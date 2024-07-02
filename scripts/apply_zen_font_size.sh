#!/bin/bash

FONT_SIZE=20

# Ensure the Alacritty config directory exists
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

DOTFILES_PATH="$HOME/code/dotfiles"

# Copy current font size to small-size.toml
cp "$DOTFILES_PATH/alacritty/font-size.toml" "$DOTFILES_PATH/fonts/alacritty/previous-font-size.toml"

# Create the new font size configuration
echo "[font]" >"$DOTFILES_PATH/alacritty/font-size.toml"
echo "size = $FONT_SIZE" >>"$DOTFILES_PATH/alacritty/font-size.toml"

# Logging for debugging
echo "Font size $FONT_SIZE applied successfully!"
