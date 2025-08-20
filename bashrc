# Modular bash configuration for macOS

source ~/code/dotfiles/bash/shell
source ~/code/dotfiles/bash/envs
source ~/code/dotfiles/bash/aliases
source ~/code/dotfiles/bash/functions
source ~/code/dotfiles/bash/prompt
source ~/code/dotfiles/bash/init

# Load inputrc for interactive shells
[[ $- == *i* ]] && bind -f ~/code/dotfiles/bash/inputrc
