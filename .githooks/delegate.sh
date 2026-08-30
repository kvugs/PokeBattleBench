#!/usr/bin/env bash
# Launch pre-commit through `uv run`, so the interpreter is resolved when the
# hook fires rather than baked in when the hook was installed.
#
# `pre-commit install` writes the installing checkout's venv into .git/hooks/ as
# an absolute path. Worktrees share one hooks directory, so the last worktree to
# install owned the hook and every other one failed with "`pre-commit` not
# found. Did you forget to activate your virtualenv?" even though its own venv
# was fine. `uv run` resolves the project from the working tree git is
# committing in, which is correct for every worktree at once and survives a
# deleted or rebuilt .venv.
#
# Usage: delegate.sh <hook-type> [git hook arguments...]
set -euo pipefail

hook_type="$1"
shift

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to run this repository's git hooks; see CONTRIBUTING.md." >&2
  echo "Committing from a GUI client? Make sure uv is on the PATH it starts with." >&2
  exit 1
fi

exec uv run --locked pre-commit hook-impl \
  --config=.pre-commit-config.yaml \
  --hook-type="$hook_type" \
  --hook-dir "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" \
  -- "$@"
