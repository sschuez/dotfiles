#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash matcher).
# Bare `bin/ci` triggers a deploy on protected branches (AGENTS.md:153).
# `dcr bin/ci` / `dce bin/ci` run CI in Docker with no GitHub signoff -> safe.
# Block bare `bin/ci` only when the current branch is main/develop/testing.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"
dir="${CLAUDE_PROJECT_DIR:-$PWD}"

# Bare bin/ci = not prefixed by the dcr/dce docker aliases.
if echo "$cmd" | grep -qE '(^|[;&|] *)(bin/ci)\b'; then
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  if [[ "$branch" =~ ^(main|develop|testing)$ ]]; then
    echo "BLOCKED: bare 'bin/ci' on protected branch '$branch' triggers a deploy. Use 'dcr bin/ci' instead (AGENTS.md)." >&2
    exit 2
  fi
fi

exit 0
