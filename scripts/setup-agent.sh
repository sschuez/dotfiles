#!/bin/bash
set -e

# Parse arguments
NO_DOCKER=false
while [[ $# -gt 0 ]]; do
  case $1 in
  --no-docker)
    NO_DOCKER=true
    shift
    ;;
  *)
    WORKTREE_NAME="$1"
    shift
    ;;
  esac
done

# Check if worktree name provided
if [ -z "$WORKTREE_NAME" ]; then
  echo "Usage: setup-agent <worktree-name> [--no-docker]"
  echo "Example: setup-agent backend-feature"
  echo "         setup-agent ui-fixes --no-docker"
  exit 1
fi

# Clean name for branches/directories
CLEAN_NAME=$(echo "$WORKTREE_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
REPO_NAME=$(basename "$(pwd)")
CURRENT_BRANCH=$(git branch --show-current)

echo "🤖 Creating worktree: $CLEAN_NAME"
echo "📂 From branch: $CURRENT_BRANCH"

# Create worktree directory name
WORKTREE_DIR="../${REPO_NAME}-${CLEAN_NAME}"

# Check if worktree already exists
if [ -d "$WORKTREE_DIR" ]; then
  echo "⚠️  Worktree already exists at $WORKTREE_DIR"
  echo "Remove with: git worktree remove $WORKTREE_DIR --force"
  exit 1
fi

# Create the worktree with new branch
BRANCH_NAME="feat/${CLEAN_NAME}"
echo "🌿 Creating branch: $BRANCH_NAME"
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$CURRENT_BRANCH"

echo "✅ Worktree created at: $WORKTREE_DIR"

# Auto-setup Docker environment if bin/docker-env exists
if [ "$NO_DOCKER" = false ] && [ -f "bin/docker-env" ]; then
  echo ""
  echo "🐳 Setting up Docker environment..."

  # Function to check if port is in use (by Docker or system)
  is_port_in_use() {
    local port=$1
    # Check Docker containers
    docker ps --format "table {{.Ports}}" 2>/dev/null | grep -q ":${port}->" && return 0
    # Check system (macOS)
    lsof -iTCP:${port} -sTCP:LISTEN &>/dev/null && return 0
    return 1
  }

  # Function to find next available port starting from base
  find_next_port() {
    local base_port=$1
    local port=$base_port
    local max_attempts=20
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
      if ! is_port_in_use $port; then
        echo $port
        return 0
      fi
      ((port++))
      ((attempt++))
    done

    echo $base_port # Fallback
    return 1
  }

  # Find next available ports
  # Start from 3001 for agent worktrees (3000 is reserved for main)
  APP_PORT=$(find_next_port 3001)
  CHROME_PORT=$((APP_PORT + 3900)) # Keep the 3900 offset convention

  # Check if Chrome port is also available, if not, find another pair
  while is_port_in_use $CHROME_PORT; do
    ((APP_PORT++))
    APP_PORT=$(find_next_port $APP_PORT)
    CHROME_PORT=$((APP_PORT + 3900))
  done

  echo "  📍 Found available ports: $APP_PORT (app), $CHROME_PORT (Chrome)"

  # Change to worktree directory and setup Docker env
  (
    cd "$WORKTREE_DIR"
    if [ -f "bin/docker-env" ]; then
      # Fix potential missing esac in docker-env script
      if ! tail -1 bin/docker-env | grep -q "esac"; then
        echo "  🔧 Fixing bin/docker-env script..."
        echo "esac" >>bin/docker-env
      fi
      echo "  🔧 Running: bin/docker-env setup $CLEAN_NAME $APP_PORT"
      bin/docker-env setup "$CLEAN_NAME" "$APP_PORT"
      echo "  ✅ Docker environment configured!"
      echo ""
      echo "  Access points:"
      echo "    App: http://localhost:$APP_PORT"
      echo "    Chrome NoVNC: http://localhost:$CHROME_PORT"
    else
      echo "  ⚠️  bin/docker-env not found in worktree"
    fi
  )
fi

# Handle Rails credentials/master key setup
if [ -f "config/credentials.yml.enc" ] || [ -f "config/application.rb" ]; then
  echo ""
  echo "🔐 Setting up Rails credentials..."
  
  # Check if master.key exists in main worktree
  if [ -f "config/master.key" ]; then
    # Read master key (it's sensitive, handle with care)
    MASTER_KEY_CONTENT=$(cat config/master.key)
    
    # Copy master.key to new worktree
    (
      cd "$WORKTREE_DIR"
      
      # Create config directory if it doesn't exist
      mkdir -p config
      
      # Write master.key with proper permissions
      echo "$MASTER_KEY_CONTENT" > config/master.key
      chmod 600 config/master.key
      
      echo "  ✅ Master key copied to worktree (config/master.key)"
      
      # If credentials.yml.enc exists in main, copy it too
      if [ -f "../${REPO_NAME}/config/credentials.yml.enc" ]; then
        cp "../${REPO_NAME}/config/credentials.yml.enc" config/credentials.yml.enc
        echo "  ✅ Credentials file copied (config/credentials.yml.enc)"
      fi
      
      # Copy database.yml if it exists and isn't already there
      if [ -f "../${REPO_NAME}/config/database.yml" ] && [ ! -f "config/database.yml" ]; then
        cp "../${REPO_NAME}/config/database.yml" config/database.yml
        echo "  ✅ Database config copied (config/database.yml)"
      fi
      
      # Handle .env files if they exist in main worktree
      if [ -f "../${REPO_NAME}/.env" ] && [ ! -f ".env" ]; then
        # Docker-env will create its own .env with ports, so we need to merge
        # First check if docker-env already created one
        if [ -f ".env" ]; then
          # Append Rails-specific env vars from main .env
          echo "" >> .env
          echo "# Rails environment variables from main worktree" >> .env
          grep -v "^COMPOSE_PROJECT_NAME\|^POSTGRES_DB\|^APP_PORT\|^CHROME_PORT" "../${REPO_NAME}/.env" >> .env 2>/dev/null || true
        else
          # Copy entire .env from main
          cp "../${REPO_NAME}/.env" .env
        fi
        echo "  ✅ Environment variables configured (.env)"
      fi
      
      # Add RAILS_MASTER_KEY to .env if not already present
      if [ -f ".env" ] && ! grep -q "^RAILS_MASTER_KEY=" .env; then
        echo "" >> .env
        echo "# Rails master key (auto-added by setup-agent)" >> .env
        echo "RAILS_MASTER_KEY=$MASTER_KEY_CONTENT" >> .env
        echo "  ✅ RAILS_MASTER_KEY added to .env"
      fi
    )
  else
    echo "  ⚠️  No master.key found in main worktree at config/master.key"
    echo "  💡 To create one, run in main worktree:"
    echo "     EDITOR=vim bin/rails credentials:edit"
    echo "  💡 Then run setup-agent again"
  fi
fi

# Open new window/tab
if command -v tmux &>/dev/null && [ -n "$TMUX" ]; then
  # We're in tmux, create new window
  tmux new-window -n "$CLEAN_NAME" -c "$WORKTREE_DIR"
  echo "📺 Tmux window '$CLEAN_NAME' created"
elif [ "$TERM_PROGRAM" = "iTerm.app" ]; then
  # We're in iTerm, create new tab
  osascript -e "
        tell application \"iTerm\"
            tell current window
                create tab with default profile
                tell current session of current tab
                    write text \"cd $WORKTREE_DIR\"
                end tell
            end tell
        end tell
    "
  echo "📱 iTerm tab created"
else
  echo "📁 Manual navigation required:"
  echo "   cd $WORKTREE_DIR"
fi

echo ""
echo "🚀 Ready to work on branch: $BRANCH_NAME"
echo ""
echo "📚 Quick Reference:"
echo "  Navigate:  cd $WORKTREE_DIR"
echo "  Merge:     git merge $BRANCH_NAME"
echo "  Cleanup:   agent-cleanup $CLEAN_NAME"
echo ""

# Docker-specific commands if Docker was set up
if [ "$NO_DOCKER" = false ] && [ -f "$WORKTREE_DIR/bin/docker-env" ]; then
  echo "🐳 Docker Commands:"
  echo "  Start:     bin/docker-env up"
  echo "  Stop:      bin/docker-env down"
  echo "  Shell:     bin/docker-env shell"
  echo "  Console:   bin/docker-env console"
  echo "  Logs:      bin/docker-env logs"
  echo "  Status:    bin/docker-env status"
  echo ""
  echo "  Access:"
  echo "    App:     http://localhost:$APP_PORT"
  echo "    Chrome:  http://localhost:$CHROME_PORT"
  echo ""
fi

echo "🧹 Cleanup Options:"
echo "  Quick:     agent-cleanup (interactive)"
echo "  Direct:    agent-cleanup $CLEAN_NAME"
echo "  Manual:    git worktree remove $WORKTREE_DIR && git branch -d $BRANCH_NAME"

