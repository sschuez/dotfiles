#!/bin/bash

# Define available themes
THEME_NAMES=("Tokyo Night" "Catppuccin Mocha" "Catppuccin Latte" "Nord" "Everforest" "Gruvbox" "Kanagawa" "Rose Pine")

# Use gum to select a theme (assuming gum is installed)
THEME=$(gum choose "${THEME_NAMES[@]}" --header "Choose your theme" --height 9 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Exit if no theme is selected
[ ! -n "$THEME" ] && exit 0

# Define theme directories
THEME_DIR="$HOME/code/dotfiles/themes"
NEOVIM_THEME_DIR="$THEME_DIR/neovim"
TMUX_THEME_DIR="$THEME_DIR/tmux"

# Function to apply the theme to iTerm2 using Python script
apply_iterm_theme() {
	export THEME=$THEME
	source ~/venvs/iterm2-env/bin/activate
	python3 $HOME/code/dotfiles/scripts/change_color_theme.py
	deactivate
}

# Apply theme to tmux
apply_tmux_theme() {
	local tmux_theme="$TMUX_THEME_DIR/$THEME.conf"
	if [ -f "$tmux_theme" ]; then
		tmux source-file "$tmux_theme"
		echo "Applied tmux theme."
	else
		echo "tmux theme file not found."
	fi
}

# Apply theme to Neovim
apply_neovim_theme() {
	local neovim_theme="$NEOVIM_THEME_DIR/$THEME.lua"
	if [ -f "$neovim_theme" ]; then
		cp "$neovim_theme" "$HOME/.config/nvim/lua/plugins/theme.lua"
		echo "Applied Neovim theme."
	else
		echo "Neovim theme file not found."
	fi
}

# Apply the selected theme
apply_iterm_theme
apply_tmux_theme
apply_neovim_theme

# Restart iTerm2 to apply the new theme
osascript -e 'tell application "iTerm" to reload preferences'

echo "Theme applied: $THEME"
echo "Restart your terminal for a full theme change."
