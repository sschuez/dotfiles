#!/bin/bash

TMUX_CONF="$HOME/code/dotfiles/tmux/.tmux.conf"

# Ensure we are on Catppuccin before toggling modes
if [ "$(tmux show-option -gqv @theme_active)" != "catppuccin" ]; then
	echo "Switching to Catppuccin theme first."
	tmux set -g @theme_active "catppuccin"

	# Delete the last line of the .tmux.conf file and set Catppuccin theme
	sed -i.bak '$ d' "$TMUX_CONF"
	echo "set -g @plugin 'catppuccin/tmux'" >>"$TMUX_CONF"

	tmux source-file "$TMUX_CONF"
fi

# Toggle between latte and mocha flavors
current_flavor=$(tmux show-option -gqv @catppuccin_flavour)

if [[ "$current_flavor" == "latte" ]]; then
	tmux set -g @catppuccin_flavour "mocha"
else
	tmux set -g @catppuccin_flavour "latte"
fi

tmux source-file "$TMUX_CONF" # Reload to apply the flavor change
tmux refresh-client -S
