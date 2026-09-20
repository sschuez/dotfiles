#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash matcher).
# Blocks commits, PRs and issue comments whose MESSAGE TEXT references AI/Claude.
#
# Only message text is inspected -- not the surrounding command. This avoids
# false positives from paths like ".claude/worktrees/..." while still catching
# AI references in the text that actually lands in git/GitHub.
# Message sources covered: -m/--message, -F/--file (file contents),
# gh --title/--body/--body-file/--subject, and here-doc bodies in the same
# command (`-F - <<'MSG'`, `--body "$(cat <<'EOF' ...)"`). Text piped in from
# elsewhere or typed into $EDITOR is invisible to a PreToolUse hook and is
# allowed through. This is a backstop, not a proof.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"

# Here-doc bodies are message text, never command text. Split them out first,
# so prose inside a here-doc (e.g. a notes file) cannot trigger the check.
heredocs="$(
  printf '%s' "$cmd" | perl -0777 -ne '
    while (/<<-?[ \t]*(["'"'"']?)([A-Za-z_][A-Za-z0-9_]*)\1[^\n]*\n(.*?)\n[ \t]*\2[ \t]*(?=\n|\z)/gs) {
      print "$3\n";
    }
  '
)"
cmd_line="$(
  printf '%s' "$cmd" | perl -0777 -pe '
    s/(<<-?[ \t]*(["'"'"']?)([A-Za-z_][A-Za-z0-9_]*)\2[^\n]*\n).*?\n([ \t]*\3[ \t]*(?=\n|\z))/$1$4/gs
  '
)"

# Only act on commit / PR / issue commands. Options may sit in between,
# e.g. `git -C <path> commit` or `gh pr --repo x create`.
printf '%s' "$cmd_line" | perl -0777 -ne '
  exit(/\bgit\b[^\n;&|]*\bcommit\b|\bgh\b[^\n;&|]*\b(?:pr|issue)\b[^\n;&|]*\b(?:create|edit|comment|review|merge)\b/i ? 0 : 1)
' || exit 0

msg="$heredocs"$'\n'

# -m / --message / --title / --body / --subject "..." (repeatable). Single- or
# double-quoted values, multi-line, with backslash-escaped quotes inside.
msg+="$(
  printf '%s' "$cmd_line" | perl -0777 -ne '
    while (/(?<![\w-])(?:-m|--message|--title|--body|--subject)[= ]+(?:'"'"'([^'"'"']*)'"'"'|"((?:[^"\\]|\\.)*)")/gs) {
      my $v = defined($1) ? $1 : $2;
      print "$v\n";
    }
  '
)"$'\n'

# -F / --file / --body-file <path>: include the file contents if readable.
# A path of "-" is stdin; its here-doc body is already in $msg above.
while IFS= read -r path; do
  [ -n "$path" ] && [ "$path" != "-" ] && [ -f "$path" ] && msg+="$(cat "$path")"$'\n'
done < <(
  printf '%s' "$cmd_line" | grep -oE -- "(-F|--file|--body-file)[= ]+[^ ]+" \
    | sed -E "s/^(-F|--file|--body-file)[= ]+//" | tr -d "'\"" || true
)

if printf '%s' "$msg" | grep -qiE 'claude|anthropic|co-authored-by|generated with|🤖'; then
  echo "BLOCKED: commit/PR text references AI. Remove any Claude/Anthropic/Co-Authored-By/AI mentions (global CLAUDE.md rule)." >&2
  exit 2
fi

exit 0
