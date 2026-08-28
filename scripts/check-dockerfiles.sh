#!/usr/bin/env bash
# Lint every Dockerfile, Compose build service, and build context in the
# project with the repository's pinned droast binary.
#
# droast resolves docker-compose.yaml to its build contexts, so this one
# command covers all three artifacts: the Dockerfile, the Compose definition,
# and the .dockerignore that bounds each context. Configuration lives in
# droast.toml; this script only assembles the environment droast needs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROOT

droast_binary="$("$SCRIPT_DIR/setup-droast.sh")"
readonly droast_binary

# droast.toml sets `[shellcheck] mode = "required"` so shell inside RUN
# instructions is linted by the same locked ShellCheck binary actionlint uses
# for workflow `run:` blocks. `required` fails loudly when that binary is
# missing, rather than silently skipping and giving two machines two answers.
readonly venv_bin="$REPO_ROOT/.venv/bin"
if [ ! -x "$venv_bin/shellcheck" ]; then
  echo "error: $venv_bin/shellcheck is missing; run 'just install' first." >&2
  exit 1
fi
export PATH="$venv_bin:$PATH"

# `--check-ignorefile true` is the current upstream default. Stating it makes
# the guarantee explicit, so a future default change cannot quietly drop the
# check that keeps each build context bounded (DF033).
cd "$REPO_ROOT"
exec "$droast_binary" --check-ignorefile true "$@" .
