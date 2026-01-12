#!/usr/bin/env bash

DOTFILES="$HOME/code/dotfiles"
ALACRITTY_SIZE_FILE="$DOTFILES/alacritty/font-size.toml"
GHOSTTY_SIZE_FILE="$DOTFILES/ghostty/font-size.conf"

# Get current font size
CURRENT=$(grep 'size' "$ALACRITTY_SIZE_FILE" 2>/dev/null | awk '{print $3}' || echo "14")

case "$1" in
  increment) NEW=$((CURRENT + 1)) ;;
  decrement) NEW=$((CURRENT - 1)); [ "$NEW" -lt 1 ] && echo "Min size is 1" && exit 1 ;;
  *) echo "Usage: $0 {increment|decrement}" && exit 1 ;;
esac

# Write to both configs
echo -e "[font]\nsize = $NEW" > "$ALACRITTY_SIZE_FILE"
echo "font-size = $NEW" > "$GHOSTTY_SIZE_FILE"

# Reload Ghostty
killall -SIGUSR2 ghostty 2>/dev/null || true

echo "Font size: $CURRENT → $NEW"
