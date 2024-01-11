# Environment Variables
export ZSH=$HOME/.oh-my-zsh
export HOMEBREW_NO_ANALYTICS=1
export PATH="${HOME}/.rbenv/bin:${PATH}"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export NVM_DIR="$HOME/.nvm"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BUNDLER_EDITOR=code
export EDITOR=code
export PYTHONBREAKPOINT=ipdb.set_trace
export PATH="/anaconda3/bin:${HOME}/anaconda3/bin:${PATH}"
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export BUNDLER_EDITOR="'/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl' -a"

# Oh My Zsh Settings
# Used this to create tmux like terminal: https://dev.to/andrenbrandao/terminal-setup-with-zsh-tmux-dracula-theme-48lm
ZSH_THEME="common"
# ZSH_THEME="powerlevel10k/powerlevel10k"
# ZSH_THEME="robbyrussell" # Default theme lewagon
ZSH_DISABLE_COMPFIX=true
plugins=(
  git
  gitfast
  last-working-dir
  common-aliases
  sublime
  zsh-syntax-highlighting
  history-substring-search
  zsh-autosuggestions
)

# Initialization Blocks
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source "${ZSH}/oh-my-zsh.sh"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Ruby Environment (rbenv)
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Python Environment (pyenv)
type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)"

# Node Version Manager (nvm)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
autoload -U add-zsh-hook
load-nvmrc() {
  # Function to automatically call `nvm use` in directories with a `.nvmrc`
  if nvm -v &> /dev/null; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      nvm use default --silent
    fi
  fi
}
type -a nvm > /dev/null && add-zsh-hook chpwd load-nvmrc
type -a nvm > /dev/null && load-nvmrc

# Conda Initialization
__conda_setup="$('/Users/Stephen/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
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

# Custom Aliases
unalias rm
unalias lt
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
alias vim='nvim'

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

# SSH Agent Startup
SSH_ENV=$HOME/.ssh/environment
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
    echo succeeded
    chmod 600 ${SSH_ENV}
    . ${SSH_ENV} > /dev/null
    /usr/bin/ssh-add
}

if [ -f "${SSH_ENV}" ]; then
     . ${SSH_ENV} > /dev/null
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

