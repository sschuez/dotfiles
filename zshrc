# Environment Variables
export ZSH="$HOME/.oh-my-zsh"
export HOMEBREW_NO_ANALYTICS=1
export NVM_DIR="$HOME/.nvm"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR='nvim' # Assuming VSCode, change if different
export PYTHONBREAKPOINT='ipdb.set_trace'
export BUNDLER_EDITOR="'/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl' -a"

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

# Ruby Environment (rbenv)
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Python Environment (pyenv)
type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)"

# Node Version Manager (nvm)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Conda Initialization
__conda_setup="$('nvim' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/Stephen/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/Stephen/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/Stephen/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# Docker Development Environment Aliases
alias dcu="rm -f tmp/pids/server.pid && docker compose up -d && docker compose logs -f"
alias dcb="docker compose build"
alias dcbc="docker compose build --no-cache"
alias dcd="docker compose down --remove-orphans"
alias dcr="docker compose run --rm app"
alias dcx="docker compose restart"
alias dcs="docker compose stop"
alias dce="docker compose exec app"

# Git Aliases
alias gacp='function _gacp(){ git add . && git commit -m "$1" && git push; };_gacp'
alias gac='function _gac(){ git add . && git commit -m "$1"; };_gac'

# Custom Aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
alias vim='nvim'

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
