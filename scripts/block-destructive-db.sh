#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash matcher).
# Blocks destructive database operations. See feedback_never_drop_dev_db.
# Contract: exit 2 + stderr -> blocks the call and feeds the reason back to Claude.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"

destructive='db:(drop|reset|migrate:reset|schema:load|truncate)|truncate_all|\bdropdb\b|TRUNCATE +(TABLE +)?|DELETE +FROM '

if echo "$cmd" | grep -qiE "$destructive"; then
  echo "BLOCKED: destructive DB operation detected. Confirm with the user first and target only the explicitly named database (see feedback_never_drop_dev_db)." >&2
  exit 2
fi

exit 0
