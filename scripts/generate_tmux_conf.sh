#!/bin/bash

# Load theme colors
theme_file="${1:-/Users/stephenschuz/code/dotfiles/themes/tmux/gruvbox.conf}"
source "$theme_file"

# Generate tmux.conf from template
template="/Users/stephenschuz/code/dotfiles/tmux/.tmux.conf.template"
output="/Users/stephenschuz/code/dotfiles/tmux/.tmux.conf"

# Read template and replace color placeholders
cp "$template" "$output"

# Replace all color variables
sed -i '' "s/COLOR_BG/${COLOR_bg}/g" "$output"
sed -i '' "s/COLOR_MESSAGE_FG/${COLOR_message_fg}/g" "$output"
sed -i '' "s/COLOR_MESSAGE_BG/${COLOR_message_bg}/g" "$output"
sed -i '' "s/COLOR_PANE_BORDER_FG/${COLOR_pane_border_fg}/g" "$output"
sed -i '' "s/COLOR_ACTIVE_PANE_BORDER_FG/${COLOR_active_pane_border_fg}/g" "$output"
sed -i '' "s/COLOR_WINDOW_FG/${COLOR_window_fg}/g" "$output"
sed -i '' "s/COLOR_WINDOW_BG/${COLOR_window_bg}/g" "$output"
sed -i '' "s/COLOR_WINDOW_STATUS_BG/${COLOR_window_status_bg}/g" "$output"
sed -i '' "s/COLOR_WARNING_FG/${COLOR_warning_fg}/g" "$output"
sed -i '' "s/COLOR_OKAY_FG/${COLOR_okay_fg}/g" "$output"
sed -i '' "s/COLOR_CURRENT_DIR_BG/${COLOR_current_dir_bg}/g" "$output"
sed -i '' "s/COLOR_HIGHLIGHT_BG/${COLOR_highlight_bg}/g" "$output"
sed -i '' "s/COLOR_CLOCKMODE_FG/${COLOR_clockmode_fg}/g" "$output"
sed -i '' "s/COLOR_MODE_FG/${COLOR_mode_fg}/g" "$output"
sed -i '' "s/COLOR_MODE_BG/${COLOR_mode_bg}/g" "$output"

# Reload tmux config if tmux is running
if tmux info &>/dev/null; then
  tmux source-file "$output" 2>/dev/null || true
fi

