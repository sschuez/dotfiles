#!/bin/bash

TMUX_CONF="$HOME/code/dotfiles/tmux/.tmux.conf"
current_theme=$(tmux show-option -gqv @theme_active)

echo "Current theme before switch: $current_theme" # Debug output

# Function to clear Catppuccin background color
clear_catppuccin_flavor() {
	nord_1="#3B4252"
	tmux set -g status-bg "${nord_1}"
}

# Toggle the theme
if [[ "$current_theme" == "nord" ]]; then
	new_theme="catppuccin"
	new_plugin="set -g @plugin 'catppuccin/tmux'"
else
	new_theme="nord"
	new_plugin="set -g @plugin 'arcticicestudio/nord-tmux'"
	clear_catppuccin_flavor
fi

# Set the new theme active
tmux set -g @theme_active "$new_theme"

# Delete the last line of the .tmux.conf file
sed -i.bak '$ d' "$TMUX_CONF"

# Append the new theme plugin to the .tmux.conf file
echo "$new_plugin" >>"$TMUX_CONF"

# Reload tmux environment
tmux source-file "$TMUX_CONF"
tmux refresh-client -S
