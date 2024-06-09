#!/bin/bash

# Define available themes
THEME_NAMES=("Tokyo Night" "Catppuccin Mocha" "Catppuccin Latte" "Solarized" "Nord" "Everforest" "Gruvbox" "Kanagawa" "Rose Pine" "Jellybeans")

# Use gum to select a theme (assuming gum is installed)
THEME=$(gum choose "${THEME_NAMES[@]}" --header "Choose your theme" --height 9 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Exit if no theme is selected
[ ! -n "$THEME" ] && exit 0

# Define theme directories
THEME_DIR="$HOME/code/dotfiles/themes"
NEOVIM_THEME_DIR="$THEME_DIR/neovim"
TMUX_THEME_DIR="$THEME_DIR/tmux"
CURRENT_THEME_CONF="$HOME/code/dotfiles/tmux/.tmux.conf"
TMUX_THEME_CONF="$TMUX_THEME_DIR/${THEME}.conf"

# Function to apply the theme to iTerm2 using Python script
apply_iterm_theme() {
	export THEME=$THEME
	source ~/venvs/iterm2-env/bin/activate
	python3 $HOME/code/dotfiles/scripts/change_color_theme.py
	deactivate
}

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

# Apply the selected theme
apply_iterm_theme
apply_tmux_theme
apply_neovim_theme

echo "Theme applied: $THEME"
tmux source-file "$CURRENT_THEME_CONF"
echo "Restart your terminal for a full theme change."
