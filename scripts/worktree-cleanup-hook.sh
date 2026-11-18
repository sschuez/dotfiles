#!/usr/bin/env bash
# Claude Code WorktreeRemove hook (wired in ~/.claude/settings.json).
# All the logic lives in scripts/wt: run `wt` for what it does.
exec "$(dirname "${BASH_SOURCE[0]}")/wt" hook remove
