#!/usr/bin/env bash
# Install a pinned, verified droast release binary. The final stdout line is
# the absolute path to the ready binary.
#
# droast is the project's Dockerfile, Compose, and .dockerignore linter. It is
# bootstrapped here rather than pinned as a pre-commit `rev` because the
# upstream hook declares `language: rust`, which would build the tool from
# source with cargo on every fresh machine. Owning the version here also means
# a release moves only when a human edits this file, which is what makes a
# fast-moving upstream safe to depend on in a required gate.
set -euo pipefail

readonly DROAST_VERSION="1.6.1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TOOL_CACHE_ROOT="${POKEBATTLEBENCH_TOOL_CACHE:-$REPO_ROOT/.cache}"

# Checksums come from the release's own sha256sums.txt. Update all four
# together when bumping DROAST_VERSION; a partial update fails closed on the
# platforms you did not test.
case "$(uname -s):$(uname -m)" in
Darwin:arm64 | Darwin:aarch64)
  target="macos-arm64"
  checksum="35553c601ed4a419df7161784ef50d4935c7c0576f1d9bb8588aba22d8e0179d"
  ;;
Darwin:x86_64 | Darwin:amd64)
  target="macos-x86_64"
  checksum="7f2d7cece38829795953e957a37559815f8f94835063c78ace3e8d5f8ad0db2d"
  ;;
Linux:arm64 | Linux:aarch64)
  target="linux-arm64"
  checksum="b13e956a79b21ace526ddf8d4b196a11828564f3705c4a4aa643247817e8e29d"
  ;;
Linux:x86_64 | Linux:amd64)
  target="linux-x86_64"
  checksum="53022f2ddddb79abd6ce3c74a703d00d807ebabc8f70595c9c8b8a5f23bd91fe"
  ;;
*)
  echo "error: droast $DROAST_VERSION has no configured binary for $(uname -s) $(uname -m)." >&2
  exit 1
  ;;
esac

readonly target checksum
readonly install_dir="$TOOL_CACHE_ROOT/droast/$DROAST_VERSION/$target"
readonly binary="$install_dir/droast"

if [ -x "$binary" ] && [ "$("$binary" --version)" = "droast $DROAST_VERSION" ]; then
  echo "droast $DROAST_VERSION is ready in the project tool cache." >&2
  printf '%s\n' "$binary"
  exit 0
fi

# The release asset is a bare executable, so there is nothing to extract.
readonly asset="droast-$target"
readonly download_url="https://github.com/immanuwell/dockerfile-roast/releases/download/$DROAST_VERSION/$asset"
download_dir="$(mktemp -d "${TMPDIR:-/tmp}/droast-bootstrap.XXXXXX")"
readonly download_dir

cleanup() {
  rm -rf -- "$download_dir"
}
trap cleanup EXIT

echo "Bootstrapping droast $DROAST_VERSION from its pinned release binary." >&2
if ! curl \
  --fail \
  --location \
  --show-error \
  --silent \
  --connect-timeout 15 \
  --retry 5 \
  --retry-all-errors \
  --retry-delay 2 \
  --retry-max-time 90 \
  --output "$download_dir/$asset" \
  "$download_url"; then
  echo "error: failed to bootstrap droast $DROAST_VERSION after retrying $download_url" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum="$(sha256sum "$download_dir/$asset" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum="$(shasum -a 256 "$download_dir/$asset" | awk '{print $1}')"
else
  echo "error: failed to bootstrap droast because no SHA-256 tool is available." >&2
  exit 1
fi
readonly actual_checksum

if [ "$actual_checksum" != "$checksum" ]; then
  echo "error: failed to bootstrap droast because the release checksum did not match." >&2
  echo "expected: $checksum" >&2
  echo "actual:   $actual_checksum" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$download_dir/$asset" "$binary.pending.$$"
mv -f "$binary.pending.$$" "$binary"

if [ "$("$binary" --version)" != "droast $DROAST_VERSION" ]; then
  echo "error: failed to bootstrap the expected droast $DROAST_VERSION binary." >&2
  exit 1
fi

echo "droast $DROAST_VERSION is ready in the project tool cache." >&2
printf '%s\n' "$binary"
