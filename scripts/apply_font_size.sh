#!/usr/bin/env bash

# Set the base path for your dotfiles
DOTFILES_PATH="$HOME/code/dotfiles"

FONT_SIZE=$(gum choose "12" "13" "14" "15" "16" "18" "20" "22" "Cancel" --header "Choose your font size:" --height 6 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# If the user chooses "Cancel" or no selection is made, exit the script
if [ -z "$FONT_SIZE" ] || [ "$FONT_SIZE" = "cancel" ]; then
	echo "No font size selected. Exiting..."
	exit 0
fi

# Ensure the Alacritty config directory exists
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

# Create the new font size configuration
echo "[font]" >"$DOTFILES_PATH/alacritty/font-size.toml"
echo "size = $FONT_SIZE" >>"$DOTFILES_PATH/alacritty/font-size.toml"

# Logging for debugging
echo "Font size $FONT_SIZE applied successfully!"
