#!/bin/zsh

# Explicitly set the PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

# Source the zshrc file to load environment variables and functions
source ~/.zshrc

# Open Alacritty and execute the ta command in the background
nohup /Applications/Alacritty.app/Contents/MacOS/alacritty -e zsh -ic 'source ~/.zshrc; ta; exec zsh' > /dev/null 2>&1 &
