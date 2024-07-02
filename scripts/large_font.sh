#!/bin/bash

# Ensure the Alacritty config directory exists
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

DOTFILES_PATH="$HOME/code/dotfiles"

# Copy the appropriate Alacritty font configuration
cp "$DOTFILES_PATH/fonts/alacritty/large-font.toml" "$DOTFILES_PATH/alacritty/font-size.toml"

# Logging for debugging
echo "Large font size applied successfully!"
