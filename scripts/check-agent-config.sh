#!/usr/bin/env bash
# Validate the shared agent instructions and dual-host project skill layout.
set -euo pipefail

fail() {
  echo "error: $*" >&2
  failed=true
}

failed=false

if [ ! -L CLAUDE.md ]; then
  fail "CLAUDE.md must be a symlink to AGENTS.md"
elif [ "$(readlink CLAUDE.md)" != "AGENTS.md" ]; then
  fail "CLAUDE.md must use the relative target AGENTS.md"
fi

for directory in .agents/skills .claude/skills; do
  if [ ! -d "$directory" ]; then
    fail "$directory must exist"
  fi
done

for skill_directory in .agents/skills/*; do
  [ -e "$skill_directory" ] || continue
  skill_name="$(basename "$skill_directory")"
  claude_skill=".claude/skills/$skill_name"

  if [ ! -d "$skill_directory" ]; then
    fail "$skill_directory must be a directory"
    continue
  fi
  if [ ! -f "$skill_directory/SKILL.md" ]; then
    fail "$skill_directory must contain SKILL.md"
  fi
  if [ ! -L "$claude_skill" ]; then
    fail "$claude_skill must be a symlink to ../../$skill_directory"
  elif [ "$(readlink "$claude_skill")" != "../../$skill_directory" ]; then
    fail "$claude_skill must use the relative target ../../$skill_directory"
  fi
done

for claude_skill in .claude/skills/*; do
  [ -e "$claude_skill" ] || [ -L "$claude_skill" ] || continue
  skill_name="$(basename "$claude_skill")"
  canonical_skill=".agents/skills/$skill_name"

  if [ ! -L "$claude_skill" ]; then
    fail "$claude_skill must be a symlink, not a copied skill"
  fi
  if [ ! -d "$canonical_skill" ]; then
    fail "$claude_skill has no canonical directory at $canonical_skill"
  fi
done

if [ "$failed" = true ]; then
  exit 1
fi

echo "Agent instructions and skill discovery paths are consistent."
