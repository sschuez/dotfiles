#!/usr/bin/env bash

DOTFILES="$HOME/code/dotfiles"
ALACRITTY_SIZE_FILE="$DOTFILES/alacritty/font-size.toml"
GHOSTTY_SIZE_FILE="$DOTFILES/ghostty/font-size.conf"

# Write font size to both configs
write_font_size() {
  local size=$1

  # Alacritty
  echo "[font]" > "$ALACRITTY_SIZE_FILE"
  echo "size = $size" >> "$ALACRITTY_SIZE_FILE"

  # Ghostty
  echo "font-size = $size" > "$GHOSTTY_SIZE_FILE"

  # Reload Ghostty
  killall -SIGUSR2 ghostty 2>/dev/null || true
}

# Get current font size
get_current_size() {
  grep 'size' "$ALACRITTY_SIZE_FILE" 2>/dev/null | awk '{print $3}' || echo "14"
}

CURRENT=$(get_current_size)

# Build menu with current size indicator
build_menu() {
  for size in 12 13 14 15 16 18 20 22; do
    [ "$size" = "$CURRENT" ] && echo "$size *" || echo "$size"
  done
  echo "Cancel"
}

SELECTION=$(build_menu | gum choose --header "Choose font size (current: $CURRENT):")

[[ -z "$SELECTION" || "$SELECTION" == "Cancel" ]] && echo "No size selected." && exit 0

# Remove the " *" suffix if present
SIZE="${SELECTION% \*}"

write_font_size "$SIZE"
echo "Font size set to $SIZE"
