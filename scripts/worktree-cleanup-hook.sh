#!/bin/bash
# Claude Code WorktreeRemove hook
#
# Reads {"worktree_path": "...", "cwd": "...", ...} JSON from stdin, tears
# down the worktree's Docker resources (containers, volumes, images), then
# removes the git worktree. Always exits 0 — failures never block Claude Code.
#
# Docker project resolution, in order:
#   1. COMPOSE_PROJECT_NAME from the worktree's .env — this is what compose
#      actually used (pinned there by the create hook or bin/docker-env)
#   2. Derived <repo>_<worktree-name> (legacy fallback for worktrees created
#      before the create hook pinned the project name)
#
# The worktree BRANCH is only deleted when fully merged (git branch -d).
# Unmerged work survives as "worktree-<name>" — review or delete it manually.

set +e

INPUT=$(cat)

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

  # Prefer the project name compose actually used (pinned in the worktree
  # .env by the create hook or bin/docker-env); derive it only as fallback.
  DOCKER_PROJECT=$(grep "^COMPOSE_PROJECT_NAME=" "${WORKTREE_PATH}/.env" 2>/dev/null | tail -1 | cut -d= -f2)
  if [ -z "$DOCKER_PROJECT" ]; then
    WT_NAME=$(basename "$WORKTREE_PATH")
    CLEAN_NAME=$(echo "$WT_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    PROJECT_NAME=$(get_project_name "$CWD")
    DOCKER_PROJECT="${PROJECT_NAME}_${CLEAN_NAME}"
  fi

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

# --- Host Postgres cleanup (per-worktree databases pinned in .env) ---
#
# Host runs (e.g. bin/ci) create per-worktree databases from POSTGRES_DB /
# POSTGRES_TEST_DB in the worktree .env. Drop them with the worktree.
# Guard: only names prefixed by COMPOSE_PROJECT_NAME count as per-worktree;
# shared defaults (e.g. <repo>_development, <repo>_test) are never dropped.

if [ -f "${WORKTREE_PATH}/.env" ] && command -v psql &>/dev/null; then
  PG_ENV_FILE="${WORKTREE_PATH}/.env"
  PG_PROJECT=$(grep "^COMPOSE_PROJECT_NAME=" "$PG_ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  PG_DEV_DB=$(grep "^POSTGRES_DB=" "$PG_ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  PG_TEST_DB=$(grep "^POSTGRES_TEST_DB=" "$PG_ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  # Not always 5432. A repo whose schema needs a newer server than the default
  # cluster pins POSTGRES_PORT in .env, and the databases to drop live there.
  PG_PORT=$(grep "^POSTGRES_PORT=" "$PG_ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2)
  PG_PORT=${PG_PORT:-5432}

  drop_host_db() {
    local db="$1"
    case "$db" in
      "${PG_PROJECT}"*) ;;
      *) log "Skipping host DB (not worktree-scoped): $db"; return ;;
    esac
    case "$db" in
      *[!a-z0-9_]*) log "Skipping host DB (unexpected characters): $db"; return ;;
    esac
    log "Dropping host database: $db"
    psql -h localhost -p "$PG_PORT" -d postgres -X -q \
      -c "DROP DATABASE IF EXISTS \"$db\" WITH (FORCE)" 2>&1 | while read -r line; do log "$line"; done
  }

  # PG_PROJECT must be non-empty: with an empty prefix the scope guard above
  # would match every database name.
  if [ -n "$PG_PROJECT" ] && psql -h localhost -p "$PG_PORT" -d postgres -X -q -c "SELECT 1" &>/dev/null; then
    if [ -n "$PG_DEV_DB" ]; then
      for db in "$PG_DEV_DB" "${PG_DEV_DB}_cache" "${PG_DEV_DB}_queue" "${PG_DEV_DB}_cable"; do
        drop_host_db "$db"
      done
    fi
    if [ -n "$PG_TEST_DB" ]; then
      drop_host_db "$PG_TEST_DB"
      # Parallel testing gives each worker a database of its own, named after
      # the test one with _0.._N appended, and there are as many as the machine
      # has cores. Ask which exist rather than guess how many; drop_host_db
      # still applies the COMPOSE_PROJECT_NAME guard to every name it is given.
      while read -r worker_db; do
        [ -n "$worker_db" ] && drop_host_db "$worker_db"
      done < <(psql -h localhost -p "$PG_PORT" -d postgres -X -tAc \
        "SELECT datname FROM pg_database WHERE datname LIKE '${PG_TEST_DB}\_%'" 2>/dev/null)
    fi
  fi
fi

# --- Git worktree and branch removal ---

WT_NAME=$(basename "$WORKTREE_PATH")
BRANCH_NAME="worktree-${WT_NAME}"

if [ -d "$WORKTREE_PATH" ] && [ -n "$CWD" ]; then
  log "Removing git worktree: $WORKTREE_PATH"
  git -C "$CWD" worktree remove "$WORKTREE_PATH" --force 2>&1 | while read -r line; do log "$line"; done

  # Delete the worktree branch only if fully merged — unmerged work survives
  # for manual review (git branch -d refuses to delete unmerged branches)
  if git -C "$CWD" rev-parse --verify "$BRANCH_NAME" &>/dev/null; then
    if git -C "$CWD" branch -d "$BRANCH_NAME" >/dev/null 2>&1; then
      log "Deleted merged branch: $BRANCH_NAME"
    else
      log "Branch $BRANCH_NAME has unmerged work — keeping it (delete manually when done)"
    fi
  fi

  git -C "$CWD" worktree prune 2>/dev/null
fi

exit 0
