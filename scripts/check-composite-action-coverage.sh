#!/usr/bin/env bash
# Fail if a local composite action is not registered for Dependabot scanning.
#
# Why this exists: for the `github-actions` ecosystem, Dependabot reads
# .github/workflows and a root-level action.yml, and nothing else. A composite
# action under .github/actions/** is invisible to it, so its `uses:` pins never
# appear in a bump PR and silently fall behind the same pins in the workflows.
# Nothing fails when that happens - the two versions just drift apart - so it
# has to be caught structurally rather than by a passing gate.
#
# The fix is one `directories:` entry per composite action. This asserts the
# list stays complete when someone adds the next one.
set -euo pipefail

CONFIG="${1:-.github/dependabot.yml}"

[ -f "$CONFIG" ] || exit 0

missing=""
# Directories holding a composite action, written the way dependabot.yml
# addresses them: repository-root-relative with a leading slash.
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  # Anchored match on the quoted or bare list item, so /a/b does not satisfy
  # /a/bc and a mention inside a comment does not count as registration.
  if ! grep -qE "^[[:space:]]*-[[:space:]]*\"?${dir}\"?[[:space:]]*$" "$CONFIG"; then
    missing="${missing}  ${dir}
"
  fi
done <<EOF
$(find .github -type f \( -name action.yml -o -name action.yaml \) \
  -not -path '.github/workflows/*' |
  sed -E 's|/action\.ya?ml$||; s|^|/|' | sort -u)
EOF

if [ -n "$missing" ]; then
  echo "error: composite action(s) not registered in $CONFIG:" >&2
  printf '%s' "$missing" >&2
  cat >&2 <<'EOF'

Dependabot will never bump the `uses:` pins inside them. Add each directory to
the `directories:` list on the `github-actions` entry:

  - package-ecosystem: github-actions
    directories:
      - "/"
      - "/.github/actions/<name>"

Do not use a glob such as "**/*": Dependabot then reads a workflow twice and
opens duplicate pull requests (dependabot-core#10884).
EOF
  exit 1
fi
