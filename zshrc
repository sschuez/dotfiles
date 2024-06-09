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
zplug "plugins/last-working-dir", from:oh-my-zsh
zplug "plugins/common-aliases", from:oh-my-zsh
zplug "plugins/sublime", from:oh-my-zsh

# Load if not already installed
if ! zplug check --verbose; then
    printf "Installing zplug plugins...\n"
    zplug install
fi
# Source the plugins
zplug load

# Alias to change color themes
alias theme="$HOME/code/dotfiles/scripts/apply_theme.sh"
alias th="$HOME/code/dotfiles/scripts/apply_theme.sh"
alias vim='nvim'

# Git Aliases
alias gacp='function _gacp(){ git add . && git commit -m "$1" && git push; };_gacp'
alias gac='function _gac(){ git add . && git commit -m "$1"; };_gac'

# Docker Development Environment Aliases
alias dcu="rm -f tmp/pids/server.pid && docker compose up -d && docker compose logs -f"
alias dcb="docker compose build"
alias dcbc="docker compose build --no-cache"
alias dcd="docker compose down --remove-orphans"
alias dcr="docker compose run --rm app"
alias dcx="docker compose restart"
alias dcs="docker compose stop"
alias dce="docker compose exec app"

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
