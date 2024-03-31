#!/usr/bin/env bash

# Function to apply Catppuccin Mocha theme
apply_mocha() {
	# Mocha theme settings
	tmux set-option -g status-bg "#1e1e28"
	tmux set-option -g status-fg "#dadae8"
	tmux set-option -g message-style fg="#c2e7f0",bg="#332e41"
	tmux set-option -g message-command-style fg="#c2e7f0",bg="#332e41"
	tmux set-option -g pane-border-style fg="#332e41"
	tmux set-option -g pane-active-border-style fg="#a4b9ef"
	tmux set-window-option -g window-status-activity-style fg="#dadae8",bg="#1e1e28"
	tmux set-option -g status-right "#[fg=#e5b4e2,bg=#1e1e28]#[fg=#1e1e28,bg=#e5b4e2] #[fg=#dadae8,bg=#332e41] #W #{?client_prefix,#[fg=#e38c8f],#[fg=#b1e3ad]}#[bg=#332e41]#{?client_prefix,#[bg=#e38c8f],#[bg=#b1e3ad]}#[fg=#1e1e28] #[fg=#dadae8,bg=#332e41] #S "
	tmux set-window-option -g window-status-format "#[fg=#1e1e28,bg=#a4b9ef] #I #[fg=#dadae8,bg=#332e41] #W "
	tmux set-window-option -g window-status-current-format "#[fg=colour232,bg=#f9c096] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "
	tmux set-window-option -g clock-mode-colour "#a4b9ef"
	tmux set-window-option -g mode-style "fg=#e5b4e2 bg=#575268 bold"

	# Store the current theme as 'mocha'
	tmux set-option -g @current_theme "mocha"
}

# Function to apply Catppuccin Light theme
apply_light() {
	# Background and foreground colors
	local bg_color="#ede9e1" # Light background color
	local fg_color="#4c4f69" # Darker foreground color for contrast

	# Use a soft color for pane borders and a more distinct color for active pane borders
	local pane_border="#ababab"        # Lighter grey for pane borders
	local active_pane_border="#565f89" # Darker color for active pane border

	# Message styles could use a contrasting setup
	local message_fg="#c34043" # Reddish color for messages, example using 'Ansi 1 Color'
	local message_bg="#ede9e1" # Background color for message, same as terminal background

	# Apply colors
	tmux set-option -g status-bg "$bg_color"
	tmux set-option -g status-fg "$fg_color"
	tmux set-option -g pane-border-style fg="$pane_border"
	tmux set-option -g pane-active-border-style fg="$active_pane_border"
	tmux set-option -g message-style fg="$message_fg",bg="$message_bg"
	tmux set-option -g message-command-style fg="$message_fg",bg="$message_bg"

	# Setting the status-right to reflect the light theme's aesthetic
	tmux set-option -g status-right "#[fg=$active_pane_border,bg=$bg_color]#[fg=$bg_color,bg=$active_pane_border]Session: #S #[fg=$fg_color,bg=$bg_color]"

	# Store the current theme as 'latte'
	tmux set-option -g @current_theme "latte"
}

# Toggle the theme based on the stored '@current_theme' value
current_theme=$(tmux show-option -gv @current_theme)

if [ "$current_theme" = "mocha" ]; then
	apply_light
else
	apply_mocha
fi
