#!/bin/bash
set -e

# Check if arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: setup-agent <worktree-name>"
    echo "Example: setup-agent backend-feature"
    exit 1
fi

# Get worktree name (will also be branch name)
WORKTREE_NAME="$1"

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