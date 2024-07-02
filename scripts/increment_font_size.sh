#!/usr/bin/env bash

# Set the path to your font-size.toml
FONT_SIZE_FILE="$HOME/code/dotfiles/alacritty/font-size.toml"

# Read the current font size from the file
CURRENT_SIZE=$(grep 'size' "$FONT_SIZE_FILE" | awk '{print $3}')

# Increment the font size by 1
NEW_SIZE=$((CURRENT_SIZE + 1))

# Update the font-size.toml with the new font size
echo "[font]" >"$FONT_SIZE_FILE"
echo "size = $NEW_SIZE" >>"$FONT_SIZE_FILE"

# Logging for debugging
echo "Font size incremented to $NEW_SIZE successfully!"
