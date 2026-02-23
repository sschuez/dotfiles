#!/bin/bash
# Claude Code WorktreeRemove hook
# Reads {"worktree_path": "...", "cwd": "...", ...} from stdin
# Cleans up Docker resources, then removes the git worktree and branch
# Exit 0 always — failures don't block Claude Code

set +e

read -r INPUT

# Extract fields (jq preferred, sed fallback)
if command -v jq &>/dev/null; then
  WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty')
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
else
  WORKTREE_PATH=$(echo "$INPUT" | sed -n 's/.*"worktree_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  CWD=$(echo "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -z "$WORKTREE_PATH" ]; then
  exit 0
fi

log() { echo "[worktree-cleanup] $*" >&2; }

# --- Docker cleanup (only if project uses Docker) ---

HAS_DOCKER=false
if [ -f "${WORKTREE_PATH}/docker-compose.yml" ] || [ -f "${WORKTREE_PATH}/compose.yml" ]; then
  HAS_DOCKER=true
elif [ -f "${WORKTREE_PATH}/bin/docker-env" ]; then
  HAS_DOCKER=true
elif [ -n "$CWD" ]; then
  if [ -f "${CWD}/docker-compose.yml" ] || [ -f "${CWD}/compose.yml" ] || [ -f "${CWD}/bin/docker-env" ]; then
    HAS_DOCKER=true
  fi
fi

if $HAS_DOCKER && command -v docker &>/dev/null; then
  # Derive project name (matches logic in agent-cleanup.sh / bin/docker-env)
  get_project_name() {
    local dir="${1:-$CWD}"
    local git_name
    git_name=$(git -C "$dir" remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git$#\1#p' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    if [ -z "$git_name" ]; then
      git_name=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    fi
    echo "$git_name" | sed 's/[^a-z0-9_]/_/g'
  }

  WT_NAME=$(basename "$WORKTREE_PATH")
  CLEAN_NAME=$(echo "$WT_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  PROJECT_NAME=$(get_project_name "$CWD")
  DOCKER_PROJECT="${PROJECT_NAME}_${CLEAN_NAME}"

  log "Cleaning Docker for project: $DOCKER_PROJECT"

  # Strategy 1: docker compose down from the worktree directory (uses compose file's project name)
  if [ -d "$WORKTREE_PATH" ]; then
    COMPOSE_FILE=""
    [ -f "${WORKTREE_PATH}/docker-compose.yml" ] && COMPOSE_FILE="${WORKTREE_PATH}/docker-compose.yml"
    [ -f "${WORKTREE_PATH}/compose.yml" ] && COMPOSE_FILE="${WORKTREE_PATH}/compose.yml"

    if [ -n "$COMPOSE_FILE" ]; then
      log "Running docker compose down -v from worktree"
      docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>&1 | while read -r line; do log "$line"; done
    fi
  fi

  # Strategy 2: docker compose down with explicit project name
  if docker compose ls --filter "name=${DOCKER_PROJECT}" --format json 2>/dev/null | grep -q "$DOCKER_PROJECT"; then
    log "Running docker compose down -v -p $DOCKER_PROJECT"
    docker compose -p "$DOCKER_PROJECT" down -v --remove-orphans 2>&1 | while read -r line; do log "$line"; done
  fi

  # Strategy 3: explicit cleanup of remaining resources
  docker volume ls --format "{{.Name}}" 2>/dev/null | grep "^${DOCKER_PROJECT}" | while read -r vol; do
    log "Removing volume: $vol"
    docker volume rm "$vol" 2>/dev/null || true
  done

  docker images --format "{{.Repository}}" 2>/dev/null | grep -E "^${DOCKER_PROJECT}[_-]" | sort -u | while read -r img; do
    log "Removing image: $img"
    docker rmi "$img" 2>/dev/null || true
  done
fi

# --- Git worktree and branch removal ---

WT_NAME=$(basename "$WORKTREE_PATH")
BRANCH_NAME="worktree-${WT_NAME}"

if [ -d "$WORKTREE_PATH" ] && [ -n "$CWD" ]; then
  log "Removing git worktree: $WORKTREE_PATH"
  git -C "$CWD" worktree remove "$WORKTREE_PATH" --force 2>&1 | while read -r line; do log "$line"; done

  # Delete the worktree branch
  if git -C "$CWD" rev-parse --verify "$BRANCH_NAME" &>/dev/null; then
    log "Deleting branch: $BRANCH_NAME"
    git -C "$CWD" branch -D "$BRANCH_NAME" 2>&1 | while read -r line; do log "$line"; done
  fi

  git -C "$CWD" worktree prune 2>/dev/null
fi

exit 0
