# Environment Variables
export ZSH="$HOME/.oh-my-zsh"
export HOMEBREW_NO_ANALYTICS=1
export NVM_DIR="$HOME/.nvm"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR='nvim'

# Source theme from dotfiles themes folder
source $HOME/code/dotfiles/themes/common.zsh-theme

# Consolidate PATH
export PATH="$HOME/.rbenv/bin:/anaconda3/bin:$HOME/anaconda3/bin:./bin:./node_modules/.bin:$PATH:/usr/local/sbin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"

# Zplug (Plugin Manager) Initialization
export ZPLUG_HOME="$HOME/.zplug"
source $ZPLUG_HOME/init.zsh

# Plugin definitions
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/gitfast", from:oh-my-zsh
# zplug "plugins/last-working-dir", from:oh-my-zsh
zplug "plugins/common-aliases", from:oh-my-zsh
zplug "plugins/sublime", from:oh-my-zsh

# Load if not already installed
if ! zplug check --verbose; then
    printf "Installing zplug plugins...\n"
    zplug install
fi
# Source the plugins
zplug load

# To make navigating back a folder easy START -->
autoload -Uz compinit
compinit

_cd_dotdot_complete() {
  if [[ $LBUFFER == "cd .." ]]; then
    LBUFFER+="\/"
    zle redisplay
  else
    zle complete-word
  fi
}

zle -N _cd_dotdot_complete
bindkey '^I' _cd_dotdot_complete

zstyle ':completion:*' menu select
# END <-- To make navigating back a folder easy --> Start

# Custom Aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Node Version Manager (nvm)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python Environment (pyenv)
type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)"

# Ruby Environment (rbenv)
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# SSH Agent Startup
SSH_ENV="$HOME/.ssh/environment"
function start_agent {
    echo "Initializing new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add
}
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep "${SSH_AGENT_PID}" | grep ssh-agent$ > /dev/null || start_agent;
else
    start_agent;
fi

# Created by `pipx` on 2024-06-07 14:16:16
export PATH="$PATH:/Users/stephenschuz/.local/bin"
