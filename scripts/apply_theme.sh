#!/bin/bash

THEME_DIR="$HOME/code/dotfiles/themes"
CURRENT_THEME_FILE="$THEME_DIR/.current"

# Auto-detect themes from folder names
get_themes() {
  find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

# Convert kebab-case to Title Case for display
to_display_name() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Convert Title Case back to kebab-case
to_folder_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

# Get current theme (if set)
get_current_theme() {
  [ -f "$CURRENT_THEME_FILE" ] && cat "$CURRENT_THEME_FILE"
}

# Build display names array with current theme indicator
build_menu() {
  local current=$(get_current_theme)
  local themes=$(get_themes)

  while IFS= read -r theme; do
    local display=$(to_display_name "$theme")
    if [ "$theme" = "$current" ]; then
      echo "$display *"
    else
      echo "$display"
    fi
  done <<<"$themes"
  echo "Cancel"
}

# Select theme with gum
SELECTION=$(build_menu | gum filter --header "Choose your theme")

# Handle cancel or no selection
[[ -z "$SELECTION" || "$SELECTION" == "Cancel" ]] && echo "No theme selected." && exit 0

# Remove the " *" suffix if present and convert to folder name
THEME=$(to_folder_name "${SELECTION% \*}")
THEME_PATH="$THEME_DIR/$THEME"

# Verify theme exists
[ ! -d "$THEME_PATH" ] && echo "Theme not found: $THEME" && exit 1

# Generic file copy function
apply_config() {
  local src="$1" dst="$2" app="$3"
  [ -f "$src" ] && cp "$src" "$dst" && echo "  $app"
}

echo "Applying theme: $THEME"

# Apply all configs
apply_config "$THEME_PATH/tmux.conf" "$HOME/code/dotfiles/tmux/theme.conf" "tmux"
apply_config "$THEME_PATH/alacritty.toml" "$HOME/.config/alacritty/theme.toml" "alacritty"
apply_config "$THEME_PATH/ghostty.conf" "$HOME/.config/ghostty/theme.conf" "ghostty"
apply_config "$THEME_PATH/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua" "neovim"

# Reload tmux if running
tmux info &>/dev/null && tmux source-file "$HOME/code/dotfiles/tmux/.tmux.conf" 2>/dev/null

# Reload Ghostty
killall -SIGUSR2 ghostty 2>/dev/null || true

# Apply wallpaper
for ext in jpg png; do
  wallpaper="$THEME_PATH/wallpaper.$ext"
  if [ -f "$wallpaper" ]; then
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$wallpaper\"" 2>/dev/null
    echo "  wallpaper"
    break
  fi
done

# Set system dark/light mode based on light.mode file presence
if [ -f "$THEME_PATH/light.mode" ]; then
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null
  echo "  system: light mode"
else
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null
  echo "  system: dark mode"
fi

# Save current theme
echo "$THEME" >"$CURRENT_THEME_FILE"

echo "Done!"
