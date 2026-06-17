#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash matcher).
# Blocks commits / PRs whose MESSAGE TEXT references AI/Claude.
#
# Only the commit/PR message is inspected -- not the surrounding command. This
# avoids false positives from paths like ".claude/worktrees/..." while still
# catching AI references in the text that actually lands in git/GitHub.
# Message sources covered: -m/--message, -F/--file (file contents),
# gh --body/--body-file/--title. Text delivered via stdin (-F -, here-docs,
# pipes) or typed into $EDITOR can't be seen from a PreToolUse hook -- those
# are allowed through. This is a backstop, not a proof.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"

# Only act on commit / PR-create / PR-edit commands.
echo "$cmd" | grep -qiE 'git +commit|gh +pr +(create|edit)' || exit 0

# Collect just the message text from the command's flags.
msg=""
saw_message_flag=0

# -m / --message / --title / --body "..."  (repeatable). Capture single- or
# double-quoted values, including multi-line ones (a -m value can span a blank
# line), via a newline-aware extraction. We only scan the combined text for
# keywords later, so joining the matches with newlines is fine.
inline_values="$(
  printf '%s' "$cmd" | perl -0777 -ne '
    while (/(?:-m|--message|--title|--body)[= ]+(?:'"'"'([^'"'"']*)'"'"'|"([^"]*)")/gs) {
      my $v = defined($1) ? $1 : $2;
      $v =~ s/\n/ /g;
      print "$v\n";
    }
  '
)"
if [ -n "$inline_values" ]; then
  saw_message_flag=1
  msg+="$inline_values"$'\n'
fi

# -F / --file / --body-file <path>: include the file's contents if readable.
# A path of "-" means stdin (here-doc / pipe) -- not readable here, so we note
# that a message flag was present and skip it rather than falling back.
while IFS= read -r path; do
  [ -n "$path" ] && saw_message_flag=1
  [ -n "$path" ] && [ "$path" != "-" ] && [ -f "$path" ] && msg+="$(cat "$path")"$'\n'
done < <(
  printf '%s' "$cmd" | grep -oE -- "(-F|--file|--body-file)[= ]+[^ ]+" \
    | sed -E "s/^(-F|--file|--body-file)[= ]+//" | tr -d "'\"" || true
)

# If a message flag was present but we still isolated no text, the message lives
# somewhere we can't see (stdin / a path we couldn't read). Allow it through --
# scanning the raw command here only produces false positives on paths like
# ".claude/worktrees/...".
if [ -z "${msg//[$'\n']/}" ]; then
  [ "$saw_message_flag" -eq 1 ] && exit 0
  # No message flag at all (e.g. `git commit` opening $EDITOR): nothing for us
  # to inspect. Allow -- the editor content is invisible to a PreToolUse hook.
  exit 0
fi

if echo "$msg" | grep -qiE 'claude|anthropic|co-authored-by|generated with|🤖'; then
  echo "BLOCKED: commit/PR text references AI. Remove any Claude/Anthropic/Co-Authored-By/AI mentions (global CLAUDE.md rule)." >&2
  exit 2
fi

exit 0
