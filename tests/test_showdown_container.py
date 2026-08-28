"""Live checks for the pinned Pokémon Showdown container.

These build and run a real image, so they carry `container` (nightly only) as
well as `external`. Every command here is one the `just showdown-*` recipes
also run, so a failure is one a contributor would hit rather than a test-only
artifact.

Nothing here sleeps. Readiness comes from `docker compose up --wait`, which
blocks on the image's own health check, so the test cannot pass by guessing a
duration that happens to be long enough on one machine.
"""

from __future__ import annotations

import json
import re
import shutil
import socket
import subprocess
from collections.abc import Iterator
from pathlib import Path

import pytest

pytestmark = [pytest.mark.external, pytest.mark.container]

_REPO_ROOT = Path(__file__).resolve().parents[1]
_DOCKERFILE = _REPO_ROOT / "server" / "pokemon-showdown" / "Dockerfile"
_SERVICE = "showdown"
_IMAGE = "pokebattlebench/showdown:local"
_REVISION_LABEL = "io.github.kvugs.pokebattlebench.showdown-revision"
_HOST = "127.0.0.1"
_PORT = 8000

# Matches the Compose health check budget in the Dockerfile: 30 retries at two
# seconds. Compose returns as soon as the container is healthy, so this is a
# ceiling, not a delay.
_WAIT_TIMEOUT = "60"


def _docker(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    """Run one docker command from the repository root and capture its output."""
    return subprocess.run(
        ["docker", *args],
        cwd=_REPO_ROOT,
        capture_output=True,
        text=True,
        check=check,
    )


def _compose(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    """Run one `docker compose` command against this repository's project."""
    return _docker("compose", *args, check=check)


def _pinned_revision() -> str:
    """Read SHOWDOWN_COMMIT from the Dockerfile, so the pin has exactly one home."""
    source = _DOCKERFILE.read_text(encoding="utf-8")
    match = re.search(r"^ARG SHOWDOWN_COMMIT=([0-9a-f]{40})$", source, re.MULTILINE)
    if match is None:
        pytest.fail(f"no full-SHA SHOWDOWN_COMMIT found in {_DOCKERFILE}")
    return match.group(1)


def _container_id() -> str:
    """Return the running container's id, or an empty string when none exists."""
    return _compose("ps", "--quiet", _SERVICE).stdout.strip()


def _published_host_ips() -> list[str]:
    """Return every host address Docker published the service port on."""
    container = _container_id()
    assert container, "no container is running for the service"
    template = '{{ json (index .NetworkSettings.Ports "' + f"{_PORT}/tcp" + '") }}'
    raw = _docker("inspect", "--format", template, container).stdout.strip()
    bindings: list[dict[str, str]] = json.loads(raw)
    return [binding["HostIp"] for binding in bindings]


def _health() -> str:
    """Return the container's health status as the daemon reports it."""
    container = _container_id()
    assert container, "no container is running for the service"
    return _docker("inspect", "--format", "{{ .State.Health.Status }}", container).stdout.strip()


def _up() -> None:
    """Start the service and return only once its health check passes."""
    _compose("up", "--detach", "--wait", "--wait-timeout", _WAIT_TIMEOUT, _SERVICE)


def _down() -> None:
    """Remove the project's containers, networks, and volumes."""
    _compose("down", "--volumes", "--remove-orphans", check=False)


@pytest.fixture(scope="module")
def docker_available() -> None:
    """Skip the module unless a usable Docker daemon is present.

    A closed Docker Desktop is a missing prerequisite, not a failing test, so
    `just test-all` on a laptop reports a skip rather than a red suite.
    """
    if shutil.which("docker") is None:
        pytest.skip("docker is not installed")
    if _docker("info", check=False).returncode != 0:
        pytest.skip("the Docker daemon is not available")
    if _docker("compose", "version", check=False).returncode != 0:
        pytest.skip("the Docker Compose plugin is not available")


@pytest.fixture(scope="module")
def image_id(docker_available: None) -> str:
    """Build the service image once for the module and return its tag.

    `docker image inspect` is the proof the build produced the tag Compose
    promises, rather than this test trusting the name it was given.
    """
    _compose("build", _SERVICE)
    _docker("image", "inspect", _IMAGE)
    return _IMAGE


@pytest.fixture
def running_service(image_id: str) -> Iterator[None]:
    """Run the service for one test, and always tear it down afterwards."""
    _down()
    _up()
    try:
        yield
    finally:
        _down()


def test_image_carries_the_reviewed_revision(image_id: str) -> None:
    """The running artifact must state which upstream commit it was built from.

    Reading the expectation out of the Dockerfile rather than hardcoding it
    means bumping the pin cannot leave a stale assertion passing.
    """
    template = '{{ index .Config.Labels "' + _REVISION_LABEL + '" }}'
    labelled = _docker("inspect", "--format", template, image_id).stdout.strip()
    assert labelled == _pinned_revision()


def test_service_becomes_healthy(running_service: None) -> None:
    """`up --wait` must return with the container actually reporting healthy."""
    assert _health() == "healthy"


def test_service_publishes_only_on_loopback(running_service: None) -> None:
    """Port 8000 must answer on loopback and be published nowhere else.

    Connecting to 127.0.0.1 proves something answers, not that nothing else
    can reach it: the same connection succeeds when Docker publishes on
    0.0.0.0. Since this binding is what makes the tokenless development
    identities in config.js acceptable, assert the published address too.
    An all-interfaces publication shows up here as 0.0.0.0 and ::.
    """
    with socket.create_connection((_HOST, _PORT), timeout=5):
        pass

    published = _published_host_ips()
    assert published, f"nothing is published for {_PORT}/tcp"
    assert set(published) == {_HOST}, (
        f"port {_PORT} is published on {sorted(published)}, expected only {_HOST}"
    )


def test_stops_cleanly_and_restarts_from_fresh_state(image_id: str) -> None:
    """`down` must leave nothing behind, and the next `up` must be healthy again.

    This is what `just showdown-reset` promises: a stale runtime state is
    always one command away from being gone.
    """
    _up()
    _down()
    assert _container_id() == "", "containers survived `docker compose down`"

    _up()
    try:
        assert _health() == "healthy"
    finally:
        _down()
