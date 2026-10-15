#!/usr/bin/env bash
# Write a Claude Code theme from a dotfiles theme's terminal palette (ghostty.conf).
#
# Claude Code watches ~/.claude/themes and reloads a changed file in running
# sessions, so a theme switch recolours every open session. Select the theme once
# with "theme": "custom:dotfiles" in ~/.claude/settings.json (or via /theme).
# Token mapping follows omarchy's default/themed/claude.json.tpl.
#
# Usage: apply_claude_theme.sh <theme-dir>

theme_path="$1"
conf="$theme_path/ghostty.conf"
out_dir="$HOME/.claude/themes"

[ -f "$conf" ] || exit 0

# "key = value" from ghostty.conf, as lowercase rrggbb without the "#"
get() { sed -n "s/^$1[[:space:]]*=[[:space:]]*#\{0,1\}//p" "$conf" | head -1 | tr 'A-F' 'a-f'; }
palette() { sed -n "s/^palette[[:space:]]*=[[:space:]]*$1=#\{0,1\}//p" "$conf" | head -1 | tr 'A-F' 'a-f'; }

# mix A B P: colour A with P percent of colour B, as #rrggbb
mix() {
  local out="#" i
  for i in 0 2 4; do
    out+=$(printf '%02x' $(((16#${1:i:2} * (100 - $3) + 16#${2:i:2} * $3) / 100)))
  done
  echo "$out"
}

bg=$(get background) fg=$(get foreground) sel=$(get selection-background)
red=$(palette 1) green=$(palette 2) yellow=$(palette 3) blue=$(palette 4)
magenta=$(palette 5) cyan=$(palette 6) muted=$(palette 8)
bright_yellow=$(palette 11) bright_cyan=$(palette 14)
accent=$blue

base=dark
[ -f "$theme_path/light.mode" ] && base=light

# A monochrome palette (snow) has no red or green to tell diffs and states
# apart, so those tokens keep the base preset's colours.
status=""
if [ "$red" != "$green" ]; then
  status="
    \"success\": \"#$green\",
    \"error\": \"#$red\",
    \"diffAdded\": \"$(mix "$bg" "$green" 15)\",
    \"diffRemoved\": \"$(mix "$bg" "$red" 15)\",
    \"diffAddedDimmed\": \"$(mix "$bg" "$green" 8)\",
    \"diffRemovedDimmed\": \"$(mix "$bg" "$red" 8)\",
    \"diffAddedWord\": \"$(mix "$bg" "$green" 32)\",
    \"diffRemovedWord\": \"$(mix "$bg" "$red" 32)\","
fi

mkdir -p "$out_dir"
# Write beside the target and move it into place whole, so a running session
# never reloads a half-written file.
tmp=$(mktemp "$out_dir/.dotfiles.XXXXXX")
cat >"$tmp" <<EOF
{
  "name": "Dotfiles",
  "base": "$base",
  "overrides": {$status
    "claude": "#$accent",
    "claudeShimmer": "$(mix "$accent" "$fg" 35)",
    "text": "#$fg",
    "inverseText": "#$bg",
    "inactive": "$(mix "$fg" "$bg" 40)",
    "inactiveShimmer": "$(mix "$fg" "$bg" 25)",
    "subtle": "#$muted",
    "suggestion": "#$cyan",
    "permission": "#$blue",
    "permissionShimmer": "$(mix "$blue" "$fg" 35)",
    "remember": "#$yellow",
    "warning": "#$yellow",
    "warningShimmer": "$(mix "$yellow" "$fg" 35)",
    "merged": "#$magenta",
    "promptBorder": "#$accent",
    "promptBorderShimmer": "$(mix "$accent" "$fg" 35)",
    "planMode": "#$cyan",
    "autoAccept": "#$yellow",
    "bashBorder": "#$bright_yellow",
    "ide": "#$bright_cyan",
    "userMessageBackground": "$(mix "$bg" "$fg" 6)",
    "userMessageBackgroundHover": "$(mix "$bg" "$fg" 10)",
    "bashMessageBackgroundColor": "$(mix "$bg" "$fg" 6)",
    "memoryBackgroundColor": "$(mix "$bg" "$fg" 6)",
    "selectionBg": "#$sel",
    "rate_limit_fill": "#$accent",
    "rate_limit_empty": "$(mix "$bg" "$fg" 20)",
    "briefLabelYou": "#$yellow",
    "briefLabelClaude": "#$accent"
  }
}
EOF
mv "$tmp" "$out_dir/dotfiles.json"
echo "  claude"
