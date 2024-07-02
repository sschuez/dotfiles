#!/usr/bin/env bash

# Set the base path for your dotfiles
DOTFILES_PATH="$HOME/code/dotfiles"

FONT=$(gum choose "Cascadia Mono" "Fira Mono" "JetBrains Mono" "Meslo" "Blex Mono" "Cancel" --header "Choose your programming font:" --height 6 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

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

echo "Font settings applied successfully!"
