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
- `setup-agent <name>` - Create worktree with auto Docker setup (see below)

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

## Git Worktree & Docker Agent Setup

The `setup-agent` script creates isolated development environments for AI agents or parallel development work. Each environment gets its own git worktree and Docker containers.

### Quick Usage

```bash
# From any git repository (e.g., submissio)
setup-agent feature-auth      # Creates worktree + auto Docker setup
setup-agent bug-fix --no-docker  # Creates worktree only (skip Docker)
```

### What it does

1. **Creates a git worktree** with branch `feat/<name>` in `../<repo>-<name>/`
2. **Auto-detects Docker setup** - if `bin/docker-env` exists in the repo
3. **Finds available ports** automatically (checks Docker & system)
4. **Configures isolated Docker** environment with unique containers/volumes
5. **Opens new tmux/iTerm window** for immediate work

### Port Allocation

The script intelligently finds free ports:
- **Main worktree**: Always uses 3000 (app) / 7900 (Chrome)
- **Agent worktrees**: Auto-increments from 3001/7901, 3002/7902, etc.
- **Conflict detection**: Checks both Docker containers and system ports

### Example Workflow

```bash
# In main submissio directory
setup-agent payments-feature

# Output:
🤖 Creating worktree: payments-feature
📂 From branch: develop
🌿 Creating branch: feat/payments-feature
✅ Worktree created at: ../submissio-payments-feature

🐳 Setting up Docker environment...
📍 Found available ports: 3001 (app), 7901 (Chrome)
🔧 Running: bin/docker-env setup payments-feature 3001
✅ Docker environment configured!

Access points:
  App: http://localhost:3001
  Chrome NoVNC: http://localhost:7901
```

### Managing Worktrees

```bash
# List all worktrees
agents                # or: git worktree list
agents-status         # Show worktrees + branch status

# Switch to a worktree (each is a separate directory)
cd ~/.claude-worktrees/<project>/<agent-name>

# Cleanup when done
agent-cleanup              # Interactive - select agents to remove
agent-cleanup <name>       # Direct removal by name or path
```

The cleanup script removes the worktree, cleans up Docker environments, and optionally deletes the branch.

### Docker Environment Management

If the repository has Docker environments (like submissio):

```bash
# In the worktree directory
bin/docker-env list      # See all Docker environments
bin/docker-env current   # Check current config
bin/docker-env clean feature-old  # Clean up old environment
```

This setup allows multiple Claude agents or developers to work on different features simultaneously without any Docker conflicts or port collisions.

