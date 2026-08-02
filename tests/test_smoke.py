"""Smoke tests: proof the package imports and the toolchain is wired up.

Delete these once the real code has its own tests.
"""

import pokebattlebench


def test_package_imports() -> None:
    assert pokebattlebench.__doc__ is not None


def test_version_is_a_string() -> None:
    assert isinstance(pokebattlebench.__version__, str)
    assert pokebattlebench.__version__
