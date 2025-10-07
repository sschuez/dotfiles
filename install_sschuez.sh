#!/bin/bash

set -e

DOTFILES_DIR=~/code/dotfiles

echo "🚀 Setting up dotfiles with bash configuration..."

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install modern bash
if ! brew list bash &>/dev/null; then
  echo "Installing modern bash..."
  brew install bash
fi

# Add Homebrew bash to /etc/shells if not already there
if ! grep -q "/opt/homebrew/bin/bash" /etc/shells; then
  echo "Adding Homebrew bash to /etc/shells (requires sudo)..."
  echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells
fi

# Create backup directory for existing configs
BACKUP_DIR="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to backup and symlink
backup_and_link() {
  local source_file="$1"
  local target_file="$2"

  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    echo "Backing up existing $target_file"
    mv "$target_file" "$BACKUP_DIR/"
  fi

  echo "Linking $source_file -> $target_file"
  ln -sfv "$source_file" "$target_file"
}

# Bash configuration
echo "Setting up bash configuration..."
backup_and_link "$DOTFILES_DIR/bashrc" ~/.bashrc

# Create .bash_profile if it doesn't exist or backup existing
if [ -f ~/.bash_profile ]; then
  echo "Backing up existing .bash_profile"
  mv ~/.bash_profile "$BACKUP_DIR/"
fi

cat >~/.bash_profile <<'EOF'
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF

# Git configuration
echo "Setting up git configuration..."
backup_and_link "$DOTFILES_DIR/gitconfig" ~/.gitconfig

# Alacritty configuration
echo "Setting up Alacritty configuration..."
mkdir -p ~/.config/alacritty
backup_and_link "$DOTFILES_DIR/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml

# Starship configuration
echo "Setting up Starship prompt configuration..."
mkdir -p ~/.config
backup_and_link "$DOTFILES_DIR/bash/starship.toml" ~/.config/starship.toml

# Tmux configuration
echo "Setting up tmux configuration..."
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf

# AeroSpace configuration
echo "Setting up AeroSpace configuration..."
mkdir -p ~/.config/aerospace
backup_and_link "$DOTFILES_DIR/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml

# Change default shell to modern bash
current_shell=$(dscl . -read /Users/$USER UserShell | cut -d' ' -f2)
if [ "$current_shell" != "/opt/homebrew/bin/bash" ]; then
  echo "Changing default shell to modern bash..."
  chsh -s /opt/homebrew/bin/bash
  echo "✅ Default shell changed. You'll need to restart your terminal."
else
  echo "✅ Already using modern bash as default shell"
fi

# Install essential tools if not present
echo "Installing essential tools..."
tools_to_install=(
  "eza"                       # Modern ls replacement
  "bat"                       # Better cat
  "fzf"                       # Fuzzy finder
  "ripgrep"                   # Better grep
  "zoxide"                    # Smart cd
  "git"                       # Version control
  "neovim"                    # Text editor
  "starship"                  # Modern prompt
  "tmux"                      # Terminal multiplexer
  "nikitabobko/tap/aerospace" # Tiling window manager
)

for tool in "${tools_to_install[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "✅ $tool already installed"
  fi
done

echo ""
echo "🎉 Dotfiles installation complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Your old configurations are backed up in: $BACKUP_DIR"
echo "3. The new bash setup includes:"
echo "   - Modern bash with Unicode support"
echo "   - Simple prompt"
echo "   - Unified aliases and functions"
echo "   - API keys preserved in api_keys file"
echo ""
echo "Enjoy your minimal, fast bash setup! 🚀"
