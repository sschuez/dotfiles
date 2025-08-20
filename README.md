# Dotfiles Setup for macOS

A minimal, fast bash configuration with modern tools and modular structure.

## Quick Setup

Run the installation script to get everything configured:

```bash
~/code/dotfiles/install_sschuez.sh
```

This will:

- Install modern bash via Homebrew
- Set up all configuration symlinks
- Change your default shell to bash
- Install essential tools
- Backup your existing configurations

## What's Included

### Shell Configuration

- **Bash**: Modern bash (5.x) with Unicode support
- **Modular structure**: Separate files for aliases, functions, prompt, etc.
- **Smart prompt**: Minimal design with directory info in terminal title
- **Enhanced tools**: eza, bat, fzf, ripgrep, zoxide for better CLI experience

### Applications Configured

- **Alacritty**: Terminal emulator with custom themes and fonts
- **Tmux**: Terminal multiplexer with vim-style navigation
- **AeroSpace**: Tiling window manager with workspace automation
- **Git**: Custom aliases and workflow shortcuts
- **Neovim**: Text editor configuration (if present)

### Key Features

- **Theme management**: Switch terminal themes with `theme` command
- **Font management**: Change fonts and sizes with `font`/`fontsize` commands
- **Smart directory navigation**: `cd` command enhanced with zoxide
- **Unified aliases**: All shortcuts in one modular location
- **API keys**: Preserved in secure `api_keys` file
- **Project shortcuts**: Quick navigation to common directories

## File Structure

```
dotfiles/
├── bashrc                 # Main bash configuration
├── bash/                  # Modular bash components
│   ├── aliases           # All command shortcuts
│   ├── envs              # Environment variables
│   ├── functions         # Custom bash functions
│   ├── prompt            # Prompt configuration
│   ├── shell             # Shell settings & completion
│   ├── init              # Initialization scripts
│   └── inputrc           # Readline configuration
├── alacritty/            # Terminal emulator config
├── tmux/                 # Terminal multiplexer config
├── aerospace/            # Tiling window manager config
├── themes/               # Color themes for terminal
├── scripts/              # Utility scripts
└── api_keys              # Secure API key storage
```

## Development Environment

- **Ruby/Node.js/Python**: via `mise` (unified version manager)
- **Fallback**: `nvm`, `pyenv` if mise not available
- **Package managers**: Homebrew, Bundle, npm/yarn

## Useful Commands

### Theme Management

- `theme` or `th` - Change color theme
- `font` or `ft` - Change font family
- `fontsize` or `fs` - Change font size
- `fs+` / `fs-` - Increase/decrease font size

### Git Shortcuts

- `g` - git
- `gcm` - git commit -m
- `gac` - git add all & commit
- `gacp` - git add all, commit & push

### Development

- `dcu` - Docker compose up with logs
- `dcb` - Docker compose build
- `kl` - Kamal logs
- `be` - Bundle exec

### Navigation

- `proj` - Go to ~/code/projects
- `sub` - Go to submissio project
- `dot` - Go to dotfiles
- `..` / `...` / `....` - Go up directories

### Window Management (AeroSpace)

- `Alt + hjkl` - Focus window (left/down/up/right)
- `Alt + Shift + hjkl` - Move window
- `Alt + 1-9, a-z` - Switch to workspace
- `Alt + Shift + 1-9, a-z` - Move window to workspace
- `Alt + f` - Toggle fullscreen
- `Alt + Tab` - Switch between recent workspaces
- `Alt + /` - Toggle layout (tiles/accordion)
- `Alt + Shift + ;` - Enter service mode (config reload, reset layout)

## Reinstall Homebrew Packages

To reinstall all Homebrew packages from the saved list:

```bash
~/code/dotfiles/scripts/install_brews.sh
```

## Backup & Recovery

Your previous configurations are automatically backed up during installation to:

```
~/code/dotfiles/backup/YYYYMMDD_HHMMSS/
```

## Customization

- Add personal aliases to `bash/aliases`
- Add environment variables to `bash/envs`
- Store API keys in `api_keys`
- Customize prompt in `bash/prompt`

Enjoy your fast, minimal bash setup! 🚀

## Migration: rbenv to mise

If migrating from rbenv to mise for Ruby version management:

1. **Configure mise for Ruby idiomatic files:**
   ```bash
   mise settings add idiomatic_version_file_enable_tools ruby
   ```

2. **Install required Ruby versions:**
   ```bash
   mise install ruby@3.4.1  # or whatever version your projects need
   ```

3. **For each project with existing bundles:**
   ```bash
   rm -rf vendor/bundle      # Remove gems compiled with rbenv
   bundle install            # Reinstall with mise's Ruby
   ```

4. **Optional cleanup (removes rbenv completely):**
   ```bash
   brew uninstall rbenv
   rm -rf ~/.rbenv
   ```

The dotfiles already handle mise as the primary version manager with automatic fallback to individual tools.

