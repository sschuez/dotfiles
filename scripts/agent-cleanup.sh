#!/bin/bash
set -e

# Function to get main branch name (master, main, etc)
get_main_branch() {
  # Check if main or master exists
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    # Try to get from remote
    local remote_main=$(git ls-remote --heads origin | grep -E "(main|master)" | head -n1 | sed 's/.*refs\/heads\///')
    if [ -n "$remote_main" ]; then
      echo "$remote_main"
    else
      echo "master" # default fallback
    fi
  fi
}

# Auto-detect project name from directory or git remote (same as bin/docker-env)
get_project_name() {
  # First try to get from git remote origin
  local git_name=$(git remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git$#\1#p' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  
  # Fallback to current directory name
  if [[ -z "$git_name" ]]; then
    git_name=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  fi
  
  # Clean up any special characters
  echo "$git_name" | sed 's/[^a-z0-9_]/_/g'
}

# Function to check if bin/docker-env exists and clean Docker environment
clean_docker_env() {
  local worktree_path="$1"
  local branch_name="$2"
  
  # Extract clean name from branch (feat/xyz -> xyz)
  local clean_name=$(echo "$branch_name" | sed 's#feat/##' | sed 's/[^a-zA-Z0-9-]/-/g')
  
  if [[ -z "$clean_name" ]]; then
    return
  fi
  
  # Check if docker-env exists in the worktree or main repo
  local docker_env_script=""
  if [[ -f "$worktree_path/bin/docker-env" ]]; then
    docker_env_script="$worktree_path/bin/docker-env"
  elif [[ -f "$MAIN_WORKTREE/bin/docker-env" ]]; then
    docker_env_script="$MAIN_WORKTREE/bin/docker-env"
  fi
  
  if [[ -n "$docker_env_script" ]]; then
    local project_name=$(get_project_name)
    local docker_project="${project_name}_${clean_name//-/_}"
    
    # Check if this Docker environment exists
    if docker ps -a --format "{{.Names}}" | grep -q "^${docker_project}_"; then
      gum style --foreground 117 "  🐳 Cleaning Docker environment: $docker_project"
      
      # Stop and remove containers
      docker compose -p "${docker_project}" down -v 2>/dev/null || true
      
      # Remove any lingering volumes
      docker volume ls --format "{{.Name}}" | grep "^${docker_project}_" | xargs -r docker volume rm 2>/dev/null || true
      
      gum style --foreground 82 "  ✅ Docker environment cleaned"
    fi
  fi
}

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  gum style --foreground 196 "❌ Not in a git repository"
  exit 1
fi

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo "gum is not installed. Please install it with: brew install gum"
  exit 1
fi

# Get current branch and worktree info
CURRENT_BRANCH=$(git branch --show-current)
MAIN_BRANCH=$(get_main_branch)
MAIN_WORKTREE=$(git worktree list | head -n1 | awk '{print $1}')

# Function to get worktree info
get_worktree_info() {
  local worktree_path="$1"
  local branch_name=$(git worktree list | grep "$worktree_path" | sed -n 's/.*\[\(.*\)\].*/\1/p')
  local commit_hash=$(git worktree list | grep "$worktree_path" | awk '{print $2}')
  echo "$branch_name"
}

# Function to check if branch is merged
is_branch_merged() {
  local branch="$1"
  git branch --merged "$MAIN_BRANCH" | grep -q "$branch"
}

# If specific worktree provided as argument
if [ $# -gt 0 ]; then
  WORKTREE_TO_REMOVE="$1"

  # Check if it's a path or a branch name
  if [[ "$WORKTREE_TO_REMOVE" == /* ]] || [[ "$WORKTREE_TO_REMOVE" == ../* ]]; then
    worktree_path="$WORKTREE_TO_REMOVE"
  else
    # Try to find worktree by branch name or partial path
    worktree_path=$(git worktree list | grep -i "$WORKTREE_TO_REMOVE" | head -n1 | awk '{print $1}')

    if [ -z "$worktree_path" ]; then
      gum style --foreground 196 "❌ Worktree not found: $WORKTREE_TO_REMOVE"
      echo "Available worktrees:"
      git worktree list
      exit 1
    fi
  fi

  # Get branch name for this worktree
  branch_name=$(get_worktree_info "$worktree_path")

  # Safety check - never remove main worktree
  if [ "$worktree_path" = "$MAIN_WORKTREE" ]; then
    gum style --foreground 196 "❌ Cannot remove main worktree!"
    exit 1
  fi

  # Show what we're about to do
  gum style --border double --border-foreground 212 --padding "1 2" \
    "$(gum style --foreground 212 --bold 'Agent Cleanup')" \
    "" \
    "$(gum style --foreground 117 "Path:   $worktree_path")" \
    "$(gum style --foreground 117 "Branch: $branch_name")"

  # Confirm removal
  if gum confirm "Remove this agent (worktree + Docker + branch)?"; then
    # Check if we're currently in the worktree we're trying to remove
    if [ "$PWD" = "$worktree_path" ] || [[ "$PWD" == "$worktree_path"/* ]]; then
      gum style --foreground 214 "⚠️  Switching to main worktree..."
      cd "$MAIN_WORKTREE"
    fi

    # Clean Docker environment first (while we still have the path)
    clean_docker_env "$worktree_path" "$branch_name"

    # Remove the worktree
    gum spin --spinner dot --title "Removing worktree..." -- git worktree remove "$worktree_path" --force
    gum style --foreground 82 "✅ Worktree removed"

    # Handle branch deletion
    if is_branch_merged "$branch_name"; then
      if gum confirm "Branch is merged. Delete it?"; then
        git branch -d "$branch_name"
        gum style --foreground 82 "✅ Branch deleted"
      fi
    else
      if gum confirm --default=false "Branch is NOT merged. Force delete?"; then
        git branch -D "$branch_name"
        gum style --foreground 82 "✅ Branch force deleted"
      else
        gum style --foreground 117 "Branch kept: $branch_name"
      fi
    fi
  else
    gum style --foreground 214 "Cancelled"
    exit 0
  fi

else
  # Interactive mode - no arguments provided

  # Get all worktrees except main
  worktrees=()
  worktree_display=()
  while IFS= read -r line; do
    worktree_path=$(echo "$line" | awk '{print $1}')
    worktrees+=("$worktree_path")

    # Get branch name and create display string
    branch_name=$(get_worktree_info "$worktree_path")
    worktree_name=$(basename "$worktree_path")

    # Check if merged
    if is_branch_merged "$branch_name"; then
      merge_status="✓ merged"
      merge_color="82"
    else
      merge_status="✗ unmerged"
      merge_color="214"
    fi

    # Format: worktree-name [branch-name] (merge status)
    display_string=$(printf "%-30s %-25s %s" "$worktree_name" "[$branch_name]" "$merge_status")
    worktree_display+=("$display_string")
  done < <(git worktree list | tail -n +2)

  if [ ${#worktrees[@]} -eq 0 ]; then
    gum style --foreground 214 "No additional worktrees to clean up"
    exit 0
  fi

  # Show header
  gum style --border double --border-foreground 212 --padding "1 2" --margin "1 0" \
    "$(gum style --foreground 212 --bold 'Agent Cleanup')" \
    "" \
    "$(gum style --foreground 245 'Select agents to remove (worktree + Docker + branch)')" \
    "" \
    "$(gum style --foreground 245 'Use space to select, enter to confirm')"

  # Let user select multiple worktrees
  selected_indices=$(gum choose --no-limit --cursor="▶ " --height=10 \
    --header="$(gum style --foreground 117 'Worktree                      Branch                    Status')" \
    "${worktree_display[@]}")

  # Exit if nothing selected
  if [ -z "$selected_indices" ]; then
    gum style --foreground 214 "No worktrees selected"
    exit 0
  fi

  # Process selected worktrees
  while IFS= read -r selected; do
    # Extract worktree name from display string
    worktree_name=$(echo "$selected" | awk '{print $1}')

    # Find matching worktree path
    for i in "${!worktrees[@]}"; do
      if [[ "$(basename "${worktrees[$i]}")" == "$worktree_name" ]]; then
        worktree_path="${worktrees[$i]}"
        break
      fi
    done

    # Get branch name
    branch_name=$(get_worktree_info "$worktree_path")

    # Safety check - never remove main worktree
    if [ "$worktree_path" = "$MAIN_WORKTREE" ]; then
      gum style --foreground 196 "⚠️  Skipping main worktree"
      continue
    fi

    gum style --margin "1 0" --foreground 117 "Processing: $worktree_name"

    # Check if we're currently in the worktree we're trying to remove
    if [ "$PWD" = "$worktree_path" ] || [[ "$PWD" == "$worktree_path"/* ]]; then
      gum style --foreground 214 "  Switching to main worktree..."
      cd "$MAIN_WORKTREE"
    fi

    # Clean Docker environment first (while we still have the path)
    clean_docker_env "$worktree_path" "$branch_name"

    # Remove the worktree
    gum spin --spinner dot --title "  Removing worktree..." -- git worktree remove "$worktree_path" --force
    gum style --foreground 82 "  ✅ Worktree removed"

    # Handle branch deletion
    if is_branch_merged "$branch_name"; then
      git branch -d "$branch_name" 2>/dev/null &&
        gum style --foreground 82 "  ✅ Branch deleted (was merged)" ||
        gum style --foreground 214 "  ⚠️  Branch already deleted"
    else
      # For unmerged branches in batch mode, ask once at the end
      unmerged_branches+=("$branch_name")
    fi

  done <<<"$selected_indices"

  # Handle unmerged branches if any
  if [ ${#unmerged_branches[@]} -gt 0 ]; then
    gum style --margin "1 0" --foreground 214 "Unmerged branches remain:"
    for branch in "${unmerged_branches[@]}"; do
      echo "  • $branch"
    done

    if gum confirm --default=false "Force delete ALL unmerged branches?"; then
      for branch in "${unmerged_branches[@]}"; do
        git branch -D "$branch"
        gum style --foreground 82 "  ✅ Force deleted: $branch"
      done
    else
      gum style --foreground 117 "Unmerged branches kept"
    fi
  fi
fi

# Clean up any prunable worktrees
git worktree prune

# Also clean up any dangling Docker images/volumes
if command -v docker &>/dev/null; then
  gum style --foreground 117 "Cleaning up Docker system..."
  docker image prune -f 2>/dev/null || true
  docker volume prune -f 2>/dev/null || true
fi

# Ensure we're in a valid directory at the end
if [ ! -d "$PWD" ]; then
  cd "$MAIN_WORKTREE"
  gum style --foreground 117 "Switched to main worktree: $MAIN_WORKTREE"
fi

gum style --margin "1 0" --foreground 82 --bold "✨ Agent cleanup complete!"

