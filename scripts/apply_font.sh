#!/usr/bin/env bash

DOTFILES="$HOME/code/dotfiles"
FONTS_DIR="$DOTFILES/fonts"
CURRENT_FONT_FILE="$FONTS_DIR/.current"

# Auto-detect fonts from alacritty folder
get_fonts() {
  find "$FONTS_DIR/alacritty" -name "*.toml" ! -name "previous-*" -exec basename {} .toml \; | sort
}

# Convert kebab-case to Title Case
to_display_name() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Convert Title Case to kebab-case
to_folder_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

# Get current font
get_current_font() {
  [ -f "$CURRENT_FONT_FILE" ] && cat "$CURRENT_FONT_FILE"
}

# Build menu with current font indicator
build_menu() {
  local current=$(get_current_font)
  for font in $(get_fonts); do
    local display=$(to_display_name "$font")
    [ "$font" = "$current" ] && echo "$display *" || echo "$display"
  done
  echo "Cancel"
}

# Select font
SELECTION=$(build_menu | gum choose --header "Choose your programming font:")

# Handle cancel
[[ -z "$SELECTION" || "$SELECTION" == "Cancel" ]] && echo "No font selected." && exit 0

# Convert to folder name
FONT=$(to_folder_name "${SELECTION% \*}")

echo "Applying font: $FONT"

# Apply Alacritty font
[ -f "$FONTS_DIR/alacritty/$FONT.toml" ] && cp "$FONTS_DIR/alacritty/$FONT.toml" "$HOME/.config/alacritty/font.toml" && echo "  alacritty"

# Apply Ghostty font
[ -f "$FONTS_DIR/ghostty/$FONT.conf" ] && cp "$FONTS_DIR/ghostty/$FONT.conf" "$DOTFILES/ghostty/font.conf" && echo "  ghostty"

# Reload Ghostty
killall -SIGUSR2 ghostty 2>/dev/null || true

# Save current font
echo "$FONT" > "$CURRENT_FONT_FILE"

echo "Done!"
