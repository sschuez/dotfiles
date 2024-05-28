#!/bin/bash

#!/bin/bash

current_theme=$(tmux show-option -gqv @theme_active)

echo "Current theme before switch: $current_theme" # Debug output

if [[ "$current_theme" == "nord" ]]; then
	tmux set -g @theme_active "catppuccin"
else
	tmux set -g @theme_active "nord"
fi

# You may need to reload the tmux environment
tmux source-file ~/.tmux.conf
