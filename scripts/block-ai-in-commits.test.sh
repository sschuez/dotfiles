#!/usr/bin/env bash
# Feeds command shapes to the no-AI hook. Each case states the expected exit code:
# 2 = must be BLOCKED, 0 = must be allowed.
hook="$HOME/code/dotfiles/scripts/block-ai-in-commits.sh"
nl=$'\n'
trailer="Co-Authored-By: Claude <noreply@anthropic.com>"
fails=0

run() {
  local label="$1" expected="$2" cmd="$3" actual
  jq -n --arg c "$cmd" '{tool_input:{command:$c}}' | bash "$hook" >/dev/null 2>&1
  actual=$?
  if [ "$actual" = "$expected" ]; then mark=PASS; else mark=FAIL; fails=$((fails + 1)); fi
  printf '%-4s expected=%s actual=%s  %s\n' "$mark" "$expected" "$actual" "$label"
}

echo "--- must be blocked"
run "git commit -m with trailer" 2 \
  "git commit -m \"fix: x${nl}${nl}${trailer}\""
run "git -C <path> commit -m with trailer" 2 \
  "git -C /repo commit -m \"fix: x${nl}${nl}${trailer}\""
run "git commit -F - heredoc with trailer" 2 \
  "git commit -q -F - <<'MSG'${nl}fix: x${nl}${nl}${trailer}${nl}MSG"
run "add && git -C commit -F - heredoc with trailer" 2 \
  "git -C /repo add a && git -C /repo commit -q -F - <<'MSG'${nl}fix: x${nl}${nl}${trailer}${nl}MSG"
run "gh pr create --body \$(heredoc), no quote" 2 \
  "gh pr create --title \"t\" --body \"\$(cat <<'EOF'${nl}text${nl}Generated with Claude Code${nl}EOF${nl})\""
run "gh pr create --body \$(heredoc), body has a quote" 2 \
  "gh pr create --title \"t\" --body \"\$(cat <<'EOF'${nl}see \"Ziffer 2\"${nl}Generated with Claude Code${nl}EOF${nl})\""
run "gh pr edit --body with escaped quotes" 2 \
  "gh pr edit 1 --body \"see \\\"Ziffer 2\\\"${nl}${nl}Generated with Claude Code\""
run "gh issue comment --body with AI footer" 2 \
  "gh issue comment 1360 --body \"Umgesetzt. Generated with Claude Code\""

echo "--- must be allowed"
run "git -C commit -F - heredoc, clean" 0 \
  "git -C /repo commit -q -F - <<'MSG'${nl}fix: clean message${nl}MSG"
run "gh pr create heredoc body with quote, clean" 0 \
  "gh pr create --title \"t\" --body \"\$(cat <<'EOF'${nl}see \"Ziffer 2\"${nl}EOF${nl})\""
run ".claude/ path outside the message" 0 \
  "git -C /repo add .claude/rules/x.md && git -C /repo commit -m \"docs: update the path-scoped rule files\""
run "file heredoc that only mentions a commit" 0 \
  "cat >> notes.md <<'EOF'${nl}never add a Claude trailer to a git commit${nl}EOF"
run "unrelated command" 0 \
  "ls -la"

echo "--- failures: $fails"
exit "$fails"
