# Convenience wrappers around the exact commands CI runs, so "green locally"
# means "green in CI". Python-tool recipes use `uv run ...`; shell-backed
# recipes show their script directly below if you do not have `just` installed.
#
# Install just:  https://github.com/casey/just  (brew install just)

# `--locked` refuses a stale lockfile and never rewrites it. (`--frozen` also
# avoids writes, but skips the freshness check, so it can let local CI pass with
# dependencies that GitHub will reject.) Use `just lock` / `just add` for
# deliberate dependency changes.
UV := "uv run --locked"

# Deliberate dependency changes strip ambient index overrides so the lockfile is
# reproducible and always resolvable by CI. See docs/decisions.md.
UV_PINNED := "env -u UV_INDEX -u UV_INDEX_URL -u UV_DEFAULT_INDEX -u UV_EXTRA_INDEX_URL -u PIP_INDEX_URL -u PIP_EXTRA_INDEX_URL uv"

# -----------------------------------------------------------------------------
# WORKFLOW - which recipe belongs to which moment.
#
#   Template source      just template-ci          materialize + verify a copy
#   Once per template    just init                 fill in every placeholder
#   Once per clone       just install              locked deps + git hooks
#   Inner loop           just test                 fast tests
#                        just types                type check
#                        just format               apply Ruff fixes
#   Before pushing       just ci                   the whole required gate
#   Local battle work    just showdown-up          start the pinned server
#                        just showdown-logs        watch it
#                        just showdown-down        stop it
#   Changing the image   just dockerfiles          lint the container files
#                        just showdown-check       build and run it for real
#   Changing deps        just add / add-dev / update, then: just ci && just audit
#   Before a release     just test-all + package + audit
#   As needed            just hooks / links / cov / clean
#
# Every recipe below carries a `When:` note. `just --list` shows only the last
# comment line above each recipe, so those notes stay out of the listing; this
# file is the long form.
# -----------------------------------------------------------------------------

# List available recipes (runs when you type `just` with no args).
default:
    @just --list

# Usage:  just init my-app my-org "One-line description"
#         just init      (prompts for each value)

# When: once, immediately after creating a repo from the template. Nothing else
# works before it - the placeholder name is not a legal distribution name.
# STEP ONE for a fresh template: fill in every placeholder
init *ARGS:
    ./scripts/init-project.sh {{ ARGS }}

# Fail with a useful message instead of a TOML parse error if `init` was skipped.
# Delegates the check to the script so the sentinel lives in exactly one place.
[private]
_ready:
    @if [ -x ./scripts/init-project.sh ]; then ./scripts/init-project.sh --check; fi

# When: once after cloning. Points git at the tracked .githooks/ directory,
# whose scripts launch pre-commit through `uv run`. `pre-commit install` is
# deliberately not used, and refuses to run once core.hooksPath is set: it bakes
# an absolute venv path into .git/hooks/, which every worktree shares, so the
# last worktree to install broke all the others. See docs/decisions.md.
# Install deps + git hooks (run once after cloning)
install: _ready
    uv sync --locked
    git config core.hooksPath .githooks

# -----------------------------------------------------------------------------
# LOCAL POKEMON SHOWDOWN - reproducible development server lifecycle.
#
# These commands require the Docker Compose plugin invoked as `docker compose`.
# Startup waits for the Compose health check instead of using a fixed sleep.
# -----------------------------------------------------------------------------

[private]
_showdown_ready:
    @command -v docker >/dev/null 2>&1 || { echo "Docker is required; see CONTRIBUTING.md." >&2; exit 1; }
    @docker info >/dev/null 2>&1 || { echo "The Docker daemon is not available; start your Docker environment." >&2; exit 1; }
    @docker compose version >/dev/null 2>&1 || { echo "The Docker Compose plugin is required; see CONTRIBUTING.md." >&2; exit 1; }

# `up --wait-timeout` is a startup option, so only the recipes that start the
# service require it. Checking it everywhere would leave a contributor on an
# older Compose plugin unable to stop, inspect, or read logs from a service
# they had already started, which is exactly when they need those recipes.
[private]
_showdown_wait_ready: _showdown_ready
    @docker compose up --help | grep -q -- '--wait-timeout' || { echo "Docker Compose must support 'up --wait-timeout'; update the Compose plugin." >&2; exit 1; }

# When: before first use, or after changing the Dockerfile, server config, or
# pinned Showdown revision. A cold build requires internet access.
# Build the local Pokemon Showdown image
showdown-build: _showdown_ready
    docker compose build showdown

# When: starting local battle development. Builds changed inputs, starts in the
# background, and returns only when healthy or after the 60-second timeout.
# Start Pokemon Showdown and wait until it is healthy
showdown-up: _showdown_wait_ready
    docker compose up --detach --build --wait --wait-timeout 60 showdown

# When: checking whether the local service is running or healthy.
# Show the Pokemon Showdown container status
showdown-status: _showdown_ready
    docker compose ps showdown

# When: diagnosing startup, protocol, or battle failures. Ctrl+C stops following
# output but leaves the service running.
# Follow Pokemon Showdown logs
showdown-logs: _showdown_ready
    docker compose logs --follow showdown

# When: finished with local battle work. Stops and removes project containers
# and networks while retaining images and build cache.
# Stop and remove the local Pokemon Showdown service
showdown-down: _showdown_ready
    docker compose down --remove-orphans

# When: stale runtime state is suspected. Removes this Compose project's
# containers, networks, and volumes before rebuilding and waiting for health.
# Recreate Pokemon Showdown from fresh runtime state
showdown-reset: _showdown_wait_ready
    docker compose down --volumes --remove-orphans
    docker compose up --detach --build --wait --wait-timeout 60 showdown

# When: verifying the container end to end, and before merging any change to
# the Dockerfile, Compose file, or the pinned Showdown revision. Builds a real
# image, so a cold run takes minutes and needs internet access. CI runs this
# nightly on both supported architectures, never on a pull request.
# Build and exercise the real Pokemon Showdown container (CI: nightly)
showdown-check: _showdown_wait_ready
    {{ UV }} pytest -m container

# When: after adding or changing a hook, or on a branch where you used
# --no-verify. Manual external hooks are intentionally excluded.
# Run the fast pre-commit gate on all files
hooks: _ready
    {{ UV }} pre-commit run --all-files

# When: while editing documentation or before a release. External availability
# makes this advisory; informational CI runs the same hook on PRs and nightly.
# Check external links in Markdown (advisory; requires network)
links: _ready
    ./scripts/setup-lychee.sh >/dev/null
    {{ UV }} pre-commit run lychee --hook-stage manual --all-files

# When: while editing the Dockerfile, Compose file, or .dockerignore. `just ci`
# covers this too, through the pre-commit gate; this is the focused inner loop.
# droast.toml holds the policy; scripts/setup-droast.sh pins the binary.
# Lint Dockerfile, Compose, and .dockerignore (CI: required)
dockerfiles: _ready
    ./scripts/check-dockerfiles.sh

# When: before pushing, usually via `just ci`. Reports only, never writes - run
# `just format` to fix what it reports.
# Ruff lint + format check (CI: required)
lint: _ready
    {{ UV }} ruff check .
    {{ UV }} ruff format --check .
    ./scripts/check-lock-index.sh
    ./scripts/check-static.sh

# When: after a large edit, when `just lint` fails on style, or after a Ruff
# version bump reformats files you never touched.
# Ruff autofix + format (fixes in place)
format: _ready
    {{ UV }} ruff check --fix .
    {{ UV }} ruff format .

# When: in the inner loop, especially after changing signatures or annotations.
# basedpyright type check (CI: required)
types: _ready
    {{ UV }} basedpyright

# When: constantly - this is the inner loop. Same selection as CI's test-fast.
# Self-contained tests only (CI: required)
test: _ready
    {{ UV }} pytest -m "not external"

# When: before a release, and after touching integration or network code.
# Everything, including tests marked `external` (CI: informational)
test-all: _ready
    {{ UV }} pytest

# When: while adding tests, to find what nothing exercises. There is no coverage
# threshold and this never gates a merge.
# Coverage report, same as the informational CI job
cov: _ready
    {{ UV }} pytest --cov --cov-report=term-missing

# When: before a release, and after changing build config, adding package data,
# or moving modules. Editable installs hide these breakages; this tests the
# artifacts a user would actually install.
# Build wheel + sdist and import each in a clean environment (CI: required)
package: _ready
    ./scripts/check-package.sh

# When: right after `just add` or `just update` while you can still change the
# versions, before a release, or when an advisory lands. Runs on every PR too,
# and stays advisory because it needs network and fires on someone else's
# disclosure schedule.
# Audit locked dependencies against OSV (CI: informational; requires network)
audit: _ready
    uv audit --locked --preview-features audit-command

# When: before you push or open a PR, after updating from main, and when
# CI is red and you want it reproduced locally. These are the four primary
# generated-project jobs in ci.yml; template source runs `just template-ci`.
ci: lint types test package

# Usage:  just add httpx        just add-dev pytest-asyncio

# When: adding a runtime dependency. A library advertises a compatible lower
# bound; uv.lock still records the exact version tested in this repository.
# Add a runtime dependency with a compatible lower bound
add *ARGS: _ready
    {{ UV_PINNED }} add --bounds lower {{ ARGS }}

# When: adding a development tool. Exact pins make tool behavior and automated
# update PRs explicit without constraining users of the built library.
# Add an exactly pinned development dependency
add-dev *ARGS: _ready
    {{ UV_PINNED }} add --dev --bounds exact {{ ARGS }}

# When: after editing the dependency lists in pyproject.toml by hand.
# Re-lock after hand-editing pyproject.toml, without changing requested versions
lock: _ready
    {{ UV_PINNED }} lock
    ./scripts/check-lock-index.sh

# When: on its own branch and PR, never mixed into a feature - this can move a
# lot at once. Follow it with `just ci` and `just audit`.
#
# "no version of <pkg>" here is usually `exclude-newer` in pyproject.toml, not a
# broken dependency: the newest release is younger than the cutoff. Wait it out,
# or override for one command when the bump is urgent:
#   UV_EXCLUDE_NEWER=false just update
# Bump direct Python requirements and the full lock
update: _ready
    {{ UV }} python scripts/update-dependencies.py
    ./scripts/check-lock-index.sh

# When: maintaining this template repository itself. Never initialize the
# source tree in place; this verifies initialization in a disposable copy.
# Materialize and run the complete gate against a disposable template copy
template-ci:
    ./scripts/check-template.sh

# When: rarely - a stale cache is misbehaving, or you want a cold-start timing.
# Safe to run any time: everything here regenerates. Save any coverage report
# you still need first.
# Delete caches and build artifacts. Does not touch .venv or uv.lock.
clean:
    rm -rf .cache .pytest_cache .ruff_cache .mypy_cache htmlcov \
      .coverage .coverage.* coverage.xml coverage.txt dist build
    find . -type d -name __pycache__ -prune -exec rm -rf {} +
