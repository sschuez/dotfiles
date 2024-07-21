#!/bin/bash

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew
brew update

# Install formulae
if [ -f ~/code/dotfiles/brew-formulas.txt ]; then
  xargs brew install <~/code/dotfiles/brew-formulas.txt
fi

# Install casks
if [ -f ~/code/dotfiles/brew-casks.txt ]; then
  xargs brew install --cask <~/code/dotfiles/brew-casks.txt
fi

# Cleanup
brew cleanup
