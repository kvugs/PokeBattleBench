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

  claude_manual=false
  codex_manual=false
  if grep -Eq '^disable-model-invocation:[[:space:]]*true[[:space:]]*$' "$skill_directory/SKILL.md"; then
    claude_manual=true
  fi
  openai_metadata="$skill_directory/agents/openai.yaml"
  if [ -f "$openai_metadata" ] && grep -Eq '^[[:space:]]*allow_implicit_invocation:[[:space:]]*false[[:space:]]*$' "$openai_metadata"; then
    codex_manual=true
  fi
  if [ "$claude_manual" != "$codex_manual" ]; then
    fail "$skill_directory must configure equivalent manual-only invocation for Claude Code and Codex"
  fi

  if [ -L "$claude_skill" ]; then
    if [ "$(readlink "$claude_skill")" != "../../$skill_directory" ]; then
      fail "$claude_skill must use the relative target ../../$skill_directory"
    fi
  elif [ -d "$claude_skill" ]; then
    adapter="$claude_skill/SKILL.md"
    canonical_reference="../../../$skill_directory/SKILL.md"
    if [ ! -f "$adapter" ]; then
      fail "$claude_skill must contain a SKILL.md adapter"
    elif ! grep -Fq "  canonical-skill: \"$canonical_reference\"" "$adapter"; then
      fail "$adapter must declare metadata.canonical-skill as $canonical_reference"
    elif ! grep -Fq "\`$canonical_reference\`" "$adapter"; then
      fail "$adapter must tell Claude Code to load $canonical_reference"
    fi
  else
    fail "$claude_skill must be a canonical symlink or a host-specific adapter"
  fi
done

for claude_skill in .claude/skills/*; do
  [ -e "$claude_skill" ] || [ -L "$claude_skill" ] || continue
  skill_name="$(basename "$claude_skill")"
  canonical_skill=".agents/skills/$skill_name"

  if [ ! -L "$claude_skill" ] && [ ! -d "$claude_skill" ]; then
    fail "$claude_skill must be a canonical symlink or a host-specific adapter"
  fi
  if [ ! -d "$canonical_skill" ]; then
    fail "$claude_skill has no canonical directory at $canonical_skill"
  fi
done

if [ "$failed" = true ]; then
  exit 1
fi

echo "Agent instructions and skill discovery paths are consistent."
