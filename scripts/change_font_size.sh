#!/usr/bin/env bash

# Set the path to your font-size.toml
FONT_SIZE_FILE="$HOME/code/dotfiles/alacritty/font-size.toml"

# Read the current font size from the file
CURRENT_SIZE=$(grep 'size' "$FONT_SIZE_FILE" | awk '{print $3}')

# Check the first argument to determine whether to increment or decrement
if [ "$1" == "increment" ]; then
	NEW_SIZE=$((CURRENT_SIZE + 1))
elif [ "$1" == "decrement" ]; then
	NEW_SIZE=$((CURRENT_SIZE - 1))

	# Ensure the new size is not less than a minimum value (e.g., 1)
	if [ "$NEW_SIZE" -lt 1 ]; then
		echo "Font size cannot be less than 1. Exiting..."
		exit 1
	fi
else
	echo "Usage: $0 {increment|decrement}"
	exit 1
fi

# Update the font-size.toml with the new font size
echo "[font]" >"$FONT_SIZE_FILE"
echo "size = $NEW_SIZE" >>"$FONT_SIZE_FILE"

# Logging for debugging
echo "Font size $1ed to $NEW_SIZE successfully!"
