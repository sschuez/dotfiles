#!/bin/bash

# Ensure we are on Catppuccin before toggling modes
if [ "$(tmux show-option -gqv @theme_active)" != "catppuccin" ]; then
	echo "Switching to Catppuccin theme first."
	tmux set -g @theme_active "catppuccin"
	tmux source-file ~/.tmux.conf
fi

# Toggle between latte and mocha flavors
current_flavor=$(tmux show-option -gqv @catppuccin_flavour)
if [[ "$current_flavor" == "latte" ]]; then
	tmux set -g @catppuccin_flavour "mocha"
else
	tmux set -g @catppuccin_flavour "latte"
fi

tmux source-file ~/.tmux.conf # Reload to apply the flavor change
