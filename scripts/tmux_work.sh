#!/bin/bash

# Explicitly set the PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

# Source the bash file to load environment variables and functions
source ~/.bashrc

# Open Alacritty and execute the ta command in the background
nohup /Applications/Alacritty.app/Contents/MacOS/alacritty -e bash -ic 'source ~/.bashrc; ta; exec bash' > /dev/null 2>&1 &
