#!/usr/bin/env bash

# Set the base path for your dotfiles
DOTFILES_PATH="$HOME/code/dotfiles"

FONT=$(gum choose "Cascadia Mono" "Fira Mono" "JetBrains Mono" "Meslo" "Blex Mono" "Roboto Mono" "Ubuntu Mono" "Cancel" --header "Choose your programming font:" --height 6 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# If the user chooses "Cancel" or no selection is made, exit the script
if [ -z "$FONT" ] || [ "$FONT" = "cancel" ]; then
	echo "No font selected. Exiting..."
	exit 0
fi

# Determine the Nerd Font name
case "$FONT" in
"cascadia-mono")
	NERD_FONT="CaskaydiaMono Nerd Font"
	;;
"fira-mono")
	NERD_FONT="FiraMono Nerd Font"
	;;
"jetbrains-mono")
	NERD_FONT="JetBrainsMono NFM"
	;;
"meslo")
	NERD_FONT="MesloLGLDZ Nerd Font"
	;;
"blex-mono")
	NERD_FONT="BlexMono Nerd Font"
	;;
"roboto-mono")
	NERD_FONT="RobotoMono Nerd Font"
	;;
"ubuntu-mono")
	NERD_FONT="UbuntuMono Nerd Font"
	;;
*)
	echo "Unknown font selected."
	exit 1
	;;
esac

# Update GNOME monospace font settings
gsettings set org.gnome.desktop.interface monospace-font-name "$NERD_FONT 10"

# Ensure the Alacritty config directory exists
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

# Copy the appropriate Alacritty font configuration
cp "$DOTFILES_PATH/fonts/alacritty/$FONT.toml" "$ALACRITTY_CONFIG_DIR/font.toml"

# Update Ghostty font configuration
GHOSTTY_FONT_CONF="$HOME/.config/ghostty/font.conf"
# Read current font size from existing config or default to 13
CURRENT_SIZE=13
if [ -f "$GHOSTTY_FONT_CONF" ]; then
	CURRENT_SIZE=$(grep "^font-size" "$GHOSTTY_FONT_CONF" | sed 's/font-size = //')
fi
# Write new font config
cat > "$GHOSTTY_FONT_CONF" << EOF
# Ghostty font configuration (switched by apply_font.sh / font size scripts)
font-family = "$NERD_FONT"
font-style = Regular
font-size = $CURRENT_SIZE
EOF
# Signal Ghostty to reload
killall -SIGUSR2 ghostty 2>/dev/null || true
echo "Applied Ghostty font: $NERD_FONT"

echo "Font settings applied successfully!"
