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

# Update Ghostty font size
GHOSTTY_FONT_CONF="$HOME/.config/ghostty/font.conf"
if [ -f "$GHOSTTY_FONT_CONF" ]; then
	# Read current font family or default
	CURRENT_FONT=$(grep "^font-family" "$GHOSTTY_FONT_CONF" | sed 's/font-family = //' | tr -d '"')
	[ -z "$CURRENT_FONT" ] && CURRENT_FONT="CaskaydiaMono Nerd Font"
	# Write updated font config
	cat > "$GHOSTTY_FONT_CONF" << EOF
# Ghostty font configuration (switched by apply_font.sh / font size scripts)
font-family = "$CURRENT_FONT"
font-style = Regular
font-size = $NEW_SIZE
EOF
	# Signal Ghostty to reload
	killall -SIGUSR2 ghostty 2>/dev/null || true
fi

# Logging for debugging
echo "Font size $1ed to $NEW_SIZE successfully!"
