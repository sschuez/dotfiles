# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS dotfiles repository focused on modern bash configuration with theme management. The setup prioritizes speed, modularity, and unified theming across terminal applications.

## Installation & Setup

Primary setup command:
```bash
~/code/dotfiles/install_sschuez.sh
```

This installs modern bash, creates symlinks, backs up existing configs, and installs essential tools via Homebrew.

## Core Architecture

### Configuration Structure
- **bashrc**: Main entry point that sources all modular components
- **bash/**: Modular bash configuration split into logical files:
  - `aliases`: All command shortcuts and custom functions
  - `envs`: Environment variables and PATH configuration
  - `functions`: Utility functions (compression, media transcoding)
  - `prompt`: Prompt customization
  - `shell`: Shell settings, completion, history
  - `init`: Initialization scripts and tool setup
  - `inputrc`: Readline configuration

### Theme Management System
Unified theming across applications with per-theme folder structure (inspired by omarchy):
- **themes/**: Each theme has its own folder containing all assets:
  ```
  themes/
  ├── rose-pine/
  │   ├── alacritty.toml    # Alacritty theme colors
  │   ├── ghostty.conf      # Ghostty theme colors
  │   ├── tmux.conf         # tmux statusline theme
  │   ├── neovim.lua        # Neovim colorscheme plugin spec
  │   ├── wallpaper.png     # Desktop wallpaper (.jpg or .png)
  │   └── light.mode        # Empty file (presence = light theme)
  └── ...
  ```
- **scripts/apply_theme.sh**: Master theme switcher using gum for selection
- Automatically switches system dark/light mode based on `light.mode` file presence
- Updates tmux, Alacritty, Ghostty, Neovim, and wallpaper simultaneously

### Application Configurations
- **alacritty/**: Terminal emulator config with modular theme/font includes
- **tmux/**: Terminal multiplexer with theme sourcing
- **aerospace/**: Tiling window manager configuration
- **api_keys**: Secure storage for API tokens (preserved during installs)

## Common Commands

### Theme & Appearance
```bash
theme       # or 'th' - Interactive theme selector
font        # or 'ft' - Font family selector  
fontsize    # or 'fs' - Font size selector
fs+         # Increment font size
fs-         # Decrement font size
td          # Toggle system dark mode
```

### Development Workflow
```bash
# Git shortcuts
gacp "msg"  # Add all, commit with message, push
gac "msg"   # Add all, commit with message
gcm "msg"   # Git commit with message

# Docker development
dcu         # Docker compose up with logs
dcb         # Docker compose build
dcr         # Docker compose run app
dce         # Docker compose exec app

# Kamal deployment
kl          # Kamal app logs -f
kd          # Kamal deploy
krd         # Kamal redeploy
```

### Navigation & Tools
```bash
# Enhanced directory navigation (uses zoxide)
cd          # Smart cd with zoxide integration
proj        # ~/code/projects
sub         # ~/code/submissio/submissio with nvim
dot         # ~/code/dotfiles with nvim

# File operations
ls          # eza with icons and git status
lt          # Tree view (level 2)
ff          # fzf with bat preview
```

### Homebrew Management
```bash
bri <pkg>   # Install package and update brew lists
bric <pkg>  # Install cask and update brew lists
```

Scripts automatically maintain `brew-formulas.txt` and `brew-casks.txt` for reproducible installs.

## Development Patterns

### Multi-Agent Git Workflow
The repository includes scripts for managing multiple git worktrees:

```bash
# Setup
setup-agent <name>    # Create new worktree with branch
setup-agents          # Multi-agent setup wizard

# View
agents                # List all worktrees
agents-status         # Show worktrees + branch status

# Cleanup
agent-cleanup              # Interactive - select agents to remove
agent-cleanup <name>       # Direct removal by name or path
```

The cleanup script removes the worktree, cleans up Docker environments (if applicable), and optionally deletes the branch. Worktrees are stored in `~/.claude-worktrees/<project>/`.

### Theme Development
When adding new themes:
1. Create a new folder in `themes/<theme-name>/`
2. Add theme files:
   - `alacritty.toml` - Alacritty color configuration
   - `ghostty.conf` - Ghostty color configuration
   - `tmux.conf` - tmux statusline colors
   - `neovim.lua` - Neovim colorscheme plugin spec
   - `wallpaper.jpg` or `wallpaper.png` - Desktop wallpaper
3. For light themes: create an empty `light.mode` file in the theme folder
4. Add theme name to `THEME_NAMES` array in `scripts/apply_theme.sh`

### Configuration Backup
The install script automatically creates timestamped backups in `backup/YYYYMMDD_HHMMSS/` before making changes.

## Tool Dependencies

Essential tools installed by setup:
- **eza**: Modern ls replacement with icons
- **bat**: Syntax-highlighted cat
- **fzf**: Fuzzy finder
- **ripgrep**: Fast grep alternative  
- **zoxide**: Smart cd command
- **gum**: Interactive UI components for scripts
- **tmux**: Terminal multiplexer
- **neovim**: Text editor
- **aerospace**: Tiling window manager

## Version Management

The bash configuration supports:
- **mise**: Primary tool (unified version manager)
- **Fallbacks**: nvm, pyenv, rbenv for compatibility
- Automatic detection and PATH setup in `bash/envs`
