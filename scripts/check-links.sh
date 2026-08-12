#!/usr/bin/env bash
# Run the repository's pinned Lychee binary with its checked-in configuration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
lychee_binary="$("$SCRIPT_DIR/setup-lychee.sh")"
readonly lychee_binary

exec "$lychee_binary" "$@"
