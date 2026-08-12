#!/usr/bin/env bash
# Install a pinned, verified Lychee release without pre-commit's cargo-binstall
# bootstrap. The final stdout line is the absolute path to the ready binary.
set -euo pipefail

readonly LYCHEE_VERSION="0.24.2"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly TOOL_CACHE_ROOT="${POKEBATTLEBENCH_TOOL_CACHE:-$REPO_ROOT/.cache}"

case "$(uname -s):$(uname -m)" in
Darwin:arm64 | Darwin:aarch64)
  target="aarch64-apple-darwin"
  checksum="c9d3740ea2d891854d37116c9fba840f37b6e7c89d330e7db84ac333631c4977"
  ;;
Darwin:x86_64 | Darwin:amd64)
  target="x86_64-apple-darwin"
  checksum="887503a9cff667d322b8d0892b40bf49976eb9507af8483220a3706cdad55978"
  ;;
Linux:arm64 | Linux:aarch64)
  target="aarch64-unknown-linux-gnu"
  checksum="91a7bd65685da41b90ccb9bc867a3d649a7818042dae04ff405e55a25bddee4c"
  ;;
Linux:x86_64 | Linux:amd64)
  target="x86_64-unknown-linux-gnu"
  checksum="1f4e0ef7f6554a6ed33dd7ac144fb2e1bbed98598e7af973042fc5cd43951c9a"
  ;;
*)
  echo "error: Lychee $LYCHEE_VERSION has no configured binary for $(uname -s) $(uname -m)." >&2
  exit 1
  ;;
esac

readonly target checksum
readonly install_dir="$TOOL_CACHE_ROOT/lychee/$LYCHEE_VERSION/$target"
readonly binary="$install_dir/lychee"

if [ -x "$binary" ] && [ "$("$binary" --version)" = "lychee $LYCHEE_VERSION" ]; then
  echo "Lychee $LYCHEE_VERSION is ready in the project tool cache." >&2
  printf '%s\n' "$binary"
  exit 0
fi

readonly archive="lychee-$target.tar.gz"
readonly download_url="https://github.com/lycheeverse/lychee/releases/download/lychee-v$LYCHEE_VERSION/$archive"
download_dir="$(mktemp -d "${TMPDIR:-/tmp}/lychee-bootstrap.XXXXXX")"
readonly download_dir

cleanup() {
  rm -rf -- "$download_dir"
}
trap cleanup EXIT

echo "Bootstrapping Lychee $LYCHEE_VERSION from its pinned release binary." >&2
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
  --output "$download_dir/$archive" \
  "$download_url"; then
  echo "error: failed to bootstrap Lychee $LYCHEE_VERSION after retrying $download_url" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum="$(sha256sum "$download_dir/$archive" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum="$(shasum -a 256 "$download_dir/$archive" | awk '{print $1}')"
else
  echo "error: failed to bootstrap Lychee because no SHA-256 tool is available." >&2
  exit 1
fi
readonly actual_checksum

if [ "$actual_checksum" != "$checksum" ]; then
  echo "error: failed to bootstrap Lychee because the release checksum did not match." >&2
  echo "expected: $checksum" >&2
  echo "actual:   $actual_checksum" >&2
  exit 1
fi

tar -xzf "$download_dir/$archive" -C "$download_dir"
readonly extracted_binary="$download_dir/lychee-$target/lychee"
if [ ! -x "$extracted_binary" ]; then
  echo "error: failed to bootstrap Lychee because the verified archive has no executable." >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$extracted_binary" "$binary.pending.$$"
mv -f "$binary.pending.$$" "$binary"

if [ "$("$binary" --version)" != "lychee $LYCHEE_VERSION" ]; then
  echo "error: failed to bootstrap the expected Lychee $LYCHEE_VERSION binary." >&2
  exit 1
fi

echo "Lychee $LYCHEE_VERSION is ready in the project tool cache." >&2
printf '%s\n' "$binary"
