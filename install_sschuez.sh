#!/bin/bash

 DOTFILES_DIR=~/code/dotfiles

 # Zsh configuration
 ln -sfv "$DOTFILES_DIR/zshrc" ~/.zshrc

 # Git configuration
 ln -sfv "$DOTFILES_DIR/gitconfig" ~/.gitconfig

 # Oh My Zsh custom directory
 ln -sfnv "$DOTFILES_DIR/oh-my-zsh-custom" ~/.oh-my-zsh/custom

 # Add more symlinks for other configs as necessary