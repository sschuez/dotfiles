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
        
        echo $base_port  # Fallback
        return 1
    }
    
    # Find next available ports
    # Start from 3001 for agent worktrees (3000 is reserved for main)
    APP_PORT=$(find_next_port 3001)
    CHROME_PORT=$((APP_PORT + 3900))  # Keep the 3900 offset convention
    
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
                echo "esac" >> bin/docker-env
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

# Open new window/tab
if command -v tmux &> /dev/null && [ -n "$TMUX" ]; then
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
echo "💡 Merge back with: git merge $BRANCH_NAME"
echo "🧹 Cleanup with: git worktree remove $WORKTREE_DIR && git branch -d $BRANCH_NAME"