#!/usr/bin/env bash

# setup_multi_agent.sh - Set up multiple Claude agents in git worktrees
# Usage: setup_multi_agent.sh <feature-name> <agent1,agent2,agent3>
# Example: setup_multi_agent.sh simap-improvements api,ui,tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  print_error "Not in a git repository!"
  exit 1
fi

# Check arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <feature-name> <agent1,agent2,agent3>"
  echo "Example: $0 simap-improvements api,ui,tests"
  exit 1
fi

FEATURE=$1
AGENTS=$2
BRANCH_NAME="feature/$FEATURE"

# Get the repository name
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  print_warning "Branch $BRANCH_NAME already exists."
  if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    print_status "Already on $BRANCH_NAME"
  else
    print_status "Switching to $BRANCH_NAME"
    git checkout "$BRANCH_NAME"
  fi
else
  print_status "Creating branch $BRANCH_NAME"
  git checkout -b "$BRANCH_NAME"

  # Push the branch to origin
  print_status "Pushing branch to origin"
  git push -u origin "$BRANCH_NAME"
fi

# Create .claude/sync structure
print_status "Creating .claude/sync structure"
mkdir -p .claude/sync/{status,requests,contracts}

# Create README file
README_FILE=".claude/sync/README.md"
cat >"$README_FILE" <<EOF
# Multi-Agent Sync Directory

Active agents will communicate here. Files are temporary and should be cleaned up after feature completion.

## Current Active Agents for: $FEATURE
Branch: $BRANCH_NAME
Created: $(date '+%Y-%m-%d %H:%M')

## Agent Locations
EOF

# Create worktrees
IFS=',' read -ra AGENT_ARRAY <<<"$AGENTS"

# Check if we're on the feature branch
if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
  print_warning "You're on the feature branch. Using current directory for first agent."
  print_status "Setting up ${#AGENT_ARRAY[@]} agents (1 in current dir, $((${#AGENT_ARRAY[@]} - 1)) in worktrees)"

  # First agent uses current directory
  FIRST_AGENT="${AGENT_ARRAY[0]}"
  echo "- **$FIRST_AGENT**: . (current directory)" >>"$README_FILE"

  # Rest get worktrees with detached HEAD
  for i in "${!AGENT_ARRAY[@]}"; do
    if [ $i -eq 0 ]; then continue; fi

    agent="${AGENT_ARRAY[$i]}"
    worktree_path="../${REPO_NAME}-${FEATURE}-${agent}"

    if [ -d "$worktree_path" ]; then
      print_warning "Worktree $worktree_path already exists, skipping"
    else
      # Create worktree in detached HEAD state at the same commit
      git worktree add --detach "$worktree_path" "$BRANCH_NAME"
      print_status "Created worktree: $worktree_path (detached HEAD)"
    fi

    echo "- **$agent**: $worktree_path" >>"$README_FILE"
  done
else
  # We're not on the feature branch, so we can create normal worktrees
  print_status "Creating ${#AGENT_ARRAY[@]} worktrees"

  for agent in "${AGENT_ARRAY[@]}"; do
    worktree_path="../${REPO_NAME}-${FEATURE}-${agent}"

    if [ -d "$worktree_path" ]; then
      print_warning "Worktree $worktree_path already exists, skipping"
    else
      git worktree add "$worktree_path" "$BRANCH_NAME"
      print_status "Created worktree: $worktree_path"
    fi

    echo "- **$agent**: $worktree_path" >>"$README_FILE"
  done
fi

# Create initial coordination file (skeleton only - main agent will fill details)
PLAN_FILE=".claude/sync/contracts/${FEATURE}-plan.md"
if [ ! -f "$PLAN_FILE" ]; then
  print_status "Creating initial plan skeleton"
  cat >"$PLAN_FILE" <<EOF
# $FEATURE - Multi-Agent Development Plan

Created: $(date '+%Y-%m-%d %H:%M')
Branch: $BRANCH_NAME

## Agents
$(for agent in "${AGENT_ARRAY[@]}"; do echo "- **$agent**: ../\${REPO_NAME}-${FEATURE}-${agent}"; done)

## Objectives
*To be defined by main coordinator agent*

## Agent Responsibilities
*To be defined by main coordinator agent*

## Shared Interfaces
*To be defined by main coordinator agent*
EOF
fi

# Create a cleanup script
CLEANUP_SCRIPT=".claude/cleanup-${FEATURE}.sh"
cat >"$CLEANUP_SCRIPT" <<EOF
#!/usr/bin/env bash
# Cleanup script for $FEATURE multi-agent session

echo "Cleaning up $FEATURE worktrees..."

# Remove worktrees
$(for agent in "${AGENT_ARRAY[@]}"; do echo "git worktree remove ../\${REPO_NAME}-${FEATURE}-${agent} 2>/dev/null || echo 'Worktree ${agent} already removed'"; done)

# Clean up communication files
rm -f .claude/sync/status/${FEATURE}-*.md
rm -f .claude/sync/requests/${FEATURE}-*.md
rm -f .claude/sync/contracts/${FEATURE}-*.md

# Remove this cleanup script
rm -f "$CLEANUP_SCRIPT"

echo "Cleanup complete!"
EOF
chmod +x "$CLEANUP_SCRIPT"

# Print summary
echo
print_status "Setup complete!"
echo
echo "Created worktrees:"
for agent in "${AGENT_ARRAY[@]}"; do
  echo "  - ../${REPO_NAME}-${FEATURE}-${agent}"
done
echo
echo "Next steps:"
echo "1. Start Docker in main repo: ${GREEN}dcu${NC}"
echo "2. Start coordinator in main repo: ${GREEN}claude${NC}"
echo "3. Start agents in each worktree:"
for agent in "${AGENT_ARRAY[@]}"; do
  echo "   ${GREEN}cd ../${REPO_NAME}-${FEATURE}-${agent} && claude${NC}"
  echo "   Then use: ${YELLOW}/new-agent-in-worktree ${FEATURE}-${agent}${NC}"
done
echo
echo "4. Monitor progress:"
echo "   ${GREEN}watch -n 30 'ls -la .claude/sync/status/'${NC}"
echo
echo "5. When done, run cleanup:"
echo "   ${GREEN}.claude/cleanup-${FEATURE}.sh${NC}"
echo
print_status "Initial plan created at: $PLAN_FILE"
