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

Codex CLI uses `codex/dotfiles.tmTheme`, which the install script links into
`~/.codex/themes`. Run `/theme` in Codex and select `dotfiles` once. The theme
names terminal palette colors instead of RGB values, so a theme switch
recolors running Codex sessions, text already on screen included. The `codex`
alias sets `FORCE_COLOR=1`: in 16-color mode Codex draws its own UI with
palette colors too, so light/dark switches also apply live. The cost is the
shaded composer and prompt fills, the tinted diff lines and a reverse-video
selection. To keep `FORCE_COLOR` out of the commands Codex runs, add this to
`~/.codex/config.toml`:

    [shell_environment_policy.filters]
    FORCE_COLOR = "exclude"

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
- `wt new <name>` / `wt rm <name>` - Worktree with its own ports, Docker project and databases (see below)

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

## Worktrees (`wt`)

`scripts/wt` creates git worktrees that get their own ports, Docker project and
databases, and removes all of it again. It needs no per-repo setup. It is the
same script as in omarchy-dotfiles, so both machines behave alike.

```bash
wt new feature-auth   # create (branches from the current branch)
wt rm feature-auth    # tear down and remove (refuses if there are uncommitted changes; --force overrides)
wt ls                 # list, with slot numbers
```

Claude Code uses it too: `scripts/worktree-create-hook.sh` and
`scripts/worktree-cleanup-hook.sh` (the `WorktreeCreate` / `WorktreeRemove` hooks
in `~/.claude/settings.json`) just call `wt hook create|remove`. So
`claude --worktree <name>` gets the same setup, and removing the worktree at the
exit prompt cleans everything up.

**What a worktree gets.** It lives in `<repo>-worktrees/<name>` next to the
repo, on branch `worktree-<name>`, with a slot number (1, 2, ...). Its `.env`
(copied from the main checkout, if any) gets:

| Variable | Value |
|---|---|
| `COMPOSE_PROJECT_NAME` | `<repo>_<name>`: own containers, volumes, images |
| `<X>_PORT` | default + slot, for every `${<X>_PORT:-default}` in the compose file (`APP_PORT` 3000 -> 3001) |
| `PORT` | 3000 + slot, for dev servers run without Docker |
| `POSTGRES_DB`, `POSTGRES_TEST_DB` | `<project>_development` / `_test`, if `config/database.yml` reads them |

Gitignored files are copied per the repo's `.worktreeinclude` (`.gitignore`
syntax, the same file Claude Code uses), defaulting to `.env`,
`config/master.key` and `config/credentials/*.key`.

**Removal** runs `docker compose down` for that project (with volumes and
images), drops host Postgres databases named `<project>_*`, stops servers still
running from the worktree, removes it, and deletes the branch only if merged.

**Making a repo worktree-ready** only needs parameterized compose ports:

```yaml
ports:
  - "${APP_PORT:-3000}:3000"
```

For anything unusual, an executable `bin/worktree-setup` / `bin/worktree-teardown`
in the repo runs inside the worktree (with `WORKTREE_NAME`, `WORKTREE_DIR`,
`MAIN_DIR`, `WORKTREE_SLOT`). `scripts/docker-orphans.sh` still finds Docker
resources whose worktree is gone, for worktrees deleted by other means.

