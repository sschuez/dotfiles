#!/bin/bash

# Define available themes
THEME_NAMES=(
  "Tokyo Night"
  "Catppuccin Mocha"
  "Catppuccin Latte"
  "Nord"
  "Gruvbox"
  "Gruvbox Light"
  "Kanagawa"
  "Rose Pine"
  "Everforest Light"
  "Everforest Dark"
  "Jellybeans"
  "Snow"
  "Solarized"
  "Milky Matcha"
  "Cancel"
)

# Use gum to select a theme (assuming gum is installed)
THEME=$(gum choose "${THEME_NAMES[@]}" --header "Choose your theme" --height 9 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Exit if no theme is selected
if [ -z "$THEME" ] || [ "$THEME" == "cancel" ]; then
  echo "No theme selected."
  exit 0
fi

# Define theme directories
THEME_DIR="$HOME/code/dotfiles/themes"
NEOVIM_THEME_DIR="$THEME_DIR/neovim"
TMUX_THEME_DIR="$THEME_DIR/tmux"
TMUX_THEME_CONF="$TMUX_THEME_DIR/${THEME}.conf"
CURRENT_THEME_CONF="$HOME/code/dotfiles/tmux/.tmux.conf"
ALACRITTY_THEME_DIR="$THEME_DIR/alacritty"
ALACRITTY_THEME_CONF="$ALACRITTY_THEME_DIR/${THEME}.toml"

# Apply theme to tmux
apply_tmux_theme() {
  if [ -f "$TMUX_THEME_CONF" ]; then
    # Replace the last line in the tmux config with the new theme's source file reference
    sed -i '' '$ d' "$CURRENT_THEME_CONF"
    echo "source-file \"$TMUX_THEME_CONF\"" >>"$CURRENT_THEME_CONF"

    # Reload tmux configuration
    tmux source-file "$CURRENT_THEME_CONF"

    echo "Applied tmux theme: $THEME"
  else
    echo "tmux theme configuration file for '$THEME' not found."
  fi
}

# Apply theme to Alacritty
apply_alacritty_theme() {
  if [ -f "$ALACRITTY_THEME_CONF" ]; then
    cp "$ALACRITTY_THEME_CONF" "$HOME/.config/alacritty/theme.toml"
    echo "Applied Alacritty theme: $THEME"
  else
    echo "Alacritty theme configuration file for '$THEME' not found."
  fi
}

# Apply theme to Neovim
apply_neovim_theme() {
  local neovim_theme="$NEOVIM_THEME_DIR/$THEME.lua"
  if [ -f "$neovim_theme" ]; then
    cp "$neovim_theme" "$HOME/.config/nvim/lua/plugins/theme.lua"
    echo "Applied Neovim theme: $THEME"
  else
    echo "Neovim theme file not found."
  fi
}

# Function to get current system dark mode state
get_system_dark_mode() {
  osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode'
}

# Function to set system dark mode
set_system_dark_mode() {
  local should_be_dark=$1
  local current_dark_mode=$(get_system_dark_mode)

  if [ "$should_be_dark" = "true" ] && [ "$current_dark_mode" = "false" ]; then
    echo "Switching system to dark mode..."
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
  elif [ "$should_be_dark" = "false" ] && [ "$current_dark_mode" = "true" ]; then
    echo "Switching system to light mode..."
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
  fi
}

# Function to determine if theme is dark or light
is_dark_theme() {
  case "$THEME" in
  "catppuccin-latte" | "gruvbox-light" | "everforest-light" | "snow" | "milky-matcha" | "rose-pine" | "solarized")
    return 1 # Light theme
    ;;
  *)
    return 0 # Dark theme
    ;;
  esac
}

# Function to apply wallpaper based on theme
apply_wallpaper() {
  local wallpaper_dir="$THEME_DIR/wallpapers"
  local wallpaper_jpg="$wallpaper_dir/${THEME}.jpg"
  local wallpaper_png="$wallpaper_dir/${THEME}.png"

  if [ -f "$wallpaper_jpg" ]; then
    echo "Applying wallpaper for theme: $THEME"
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper_jpg\""
  elif [ -f "$wallpaper_png" ]; then
    echo "Applying wallpaper for theme: $THEME"
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper_png\""
  fi
}

# Apply the selected theme
# apply_iterm_theme
apply_tmux_theme
apply_alacritty_theme
apply_neovim_theme
apply_wallpaper

# Auto-switch system dark mode based on theme
if is_dark_theme; then
  set_system_dark_mode "true"
else
  set_system_dark_mode "false"
fi

echo "Theme applied: $THEME"
tmux source-file "$CURRENT_THEME_CONF"
echo "Restart your terminal for a full theme change."
