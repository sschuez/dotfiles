#!/bin/bash
# Find Docker resources whose project no longer exists on disk.
#
# worktree-cleanup-hook.sh only fires on Claude Code's WorktreeRemove event.
# Worktrees removed any other way (manual `git worktree remove`, `rm -rf`, a
# crashed session) leave their containers, volumes and images behind forever.
# This script reconciles what Docker holds against what is actually on disk.
#
# It deliberately does NOT touch build cache: BuildKit cache is global per
# builder and keyed by layer content, so it has no project to be orphaned
# from. Cap it with a GC policy instead (see docker/buildkitd-kamal.toml).
#
# Usage:
#   docker-orphans.sh              # dry run — list orphans, change nothing
#   docker-orphans.sh --prune      # remove orphaned containers/volumes/images
#   docker-orphans.sh --prune-all  # also remove orphaned DATABASE volumes
#
# Ownership is decided by Docker's own com.docker.compose.project label where
# it exists (volumes, containers) rather than by guessing from name prefixes —
# "submissio" is a prefix of "submissio_agent_<sha>", so prefix matching makes
# a dead worktree look alive. Images carry no such label, so they are matched
# by stripping the trailing -<service> and requiring an EXACT project match.

set -uo pipefail

CODE_ROOT="${CODE_ROOT:-$HOME/code}"
MODE="dry"
case "${1:-}" in
  --prune)     MODE="prune" ;;
  --prune-all) MODE="prune-all" ;;
  "")          MODE="dry" ;;
  *) echo "usage: $(basename "$0") [--prune|--prune-all]" >&2; exit 2 ;;
esac

command -v docker &>/dev/null || { echo "docker not found" >&2; exit 1; }
docker info &>/dev/null || { echo "docker daemon not running" >&2; exit 1; }

# Volume-name suffixes that hold real data rather than regenerable cache.
# Held back from --prune; only --prune-all removes them.
DATA_RE='(postgres_data|mysql_data|mariadb_data|sqlite_data|redis_data|minio_data|_data|storage|uploads)$'

# Compose service names that appear as the trailing part of a built image.
SERVICE_RE='[-_](app|web|worker|setup|jobs|sidekiq|cron|db|test)$'

# --- Discover live projects -------------------------------------------------

# Mirrors get_project_name() in worktree-cleanup-hook.sh so the two agree.
derive_project_name() {
  local dir="$1" name
  name=$(git -C "$dir" remote get-url origin 2>/dev/null \
         | sed -n 's#.*/\([^/]*\)\.git$#\1#p' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  [ -z "$name" ] && name=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  echo "$name" | sed 's/[^a-z0-9_]/_/g'
}

LIVE_PROJECTS=$(
  # Every checkout that could have run compose: main repos plus their worktrees.
  find "$CODE_ROOT" -maxdepth 5 -name .git -not -path '*/node_modules/*' 2>/dev/null \
  | while read -r gitpath; do
      repo=$(dirname "$gitpath")
      echo "$repo"
      git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
    done \
  | sort -u \
  | while read -r dir; do
      [ -d "$dir" ] || continue
      # .env wins: it records the project name compose actually used.
      grep -h '^COMPOSE_PROJECT_NAME=' "$dir/.env" 2>/dev/null \
        | tail -1 | cut -d= -f2- | tr -d '"'"'"' \r'
      derive_project_name "$dir"
      # Compose also accepts the raw directory name, which keeps its dashes
      # (busy-panini) where derive_project_name would return busy_panini.
      basename "$dir" | tr '[:upper:]' '[:lower:]'
    done \
  | sed '/^$/d' | sort -u
)

# Only RUNNING containers pin a project as live. Using `docker ps -a` here
# would let a dead worktree's own exited containers vouch for it — exactly
# the orphans this script exists to find.
RUNNING_PROJECTS=$(
  docker ps --format '{{.Label "com.docker.compose.project"}}' 2>/dev/null | sed '/^$/d' | sort -u
)

is_live() {
  local p="${1:-}"
  [ -z "$p" ] && return 1
  grep -qxF "$p" <<<"$LIVE_PROJECTS" && return 0
  grep -qxF "$p" <<<"$RUNNING_PROJECTS" && return 0
  # Tolerate dash/underscore drift between compose labels and directory names.
  local alt="${p//-/_}"
  grep -qxF "$alt" <<<"$LIVE_PROJECTS" && return 0
  return 1
}

echo "Live projects: $(wc -l <<<"$LIVE_PROJECTS" | tr -d ' ')   Running projects: $(sed '/^$/d' <<<"$RUNNING_PROJECTS" | wc -l | tr -d ' ')   (root: $CODE_ROOT)"
echo

# --- Collect orphans --------------------------------------------------------

ORPHAN_CONTAINERS=""; ORPHAN_VOLUMES=""; ORPHAN_DATA_VOLUMES=""
ORPHAN_IMAGES=""; UNLABELLED_VOLUMES=""

# Pipe-delimited so an empty label can never shift the remaining fields.
while IFS='|' read -r cid cproj cname; do
  # No compose label = not a compose container (buildkit builder, `docker run`
  # one-offs, MCP servers). Never this script's business.
  [ -z "$cproj" ] && continue
  is_live "$cproj" || ORPHAN_CONTAINERS+="$cid|$cname|$cproj"$'\n'
done < <(docker ps -a --format '{{.ID}}|{{.Label "com.docker.compose.project"}}|{{.Names}}' 2>/dev/null)

while IFS='|' read -r vol vproj; do
  case "$vol" in buildx_buildkit_*) continue ;; esac   # builder state, not a project
  if [ -z "$vproj" ]; then
    # Anonymous volumes from a Dockerfile VOLUME directive. No project, no
    # name hint — reported for review but never removed automatically.
    UNLABELLED_VOLUMES+="$vol"$'\n'
    continue
  fi
  is_live "$vproj" && continue
  if [[ "$vol" =~ $DATA_RE ]]; then
    ORPHAN_DATA_VOLUMES+="$vol|$vproj"$'\n'
  else
    ORPHAN_VOLUMES+="$vol|$vproj"$'\n'
  fi
done < <(docker volume ls --format '{{.Name}}|{{.Label "com.docker.compose.project"}}' 2>/dev/null)

# Images carry no compose project label, so derive the project by stripping the
# trailing -<service> and require an exact match. Prefix matching would treat
# submissio_secverify_<sha>-app as belonging to the live "submissio".
while read -r img; do
  case "$img" in *"/"*|"<none>"|"") continue ;; esac   # skip registry images
  [[ "$img" =~ $SERVICE_RE ]] || continue              # skip non-compose images
  proj=$(sed -E "s/${SERVICE_RE}//" <<<"$img")
  is_live "$proj" || ORPHAN_IMAGES+="$img|$proj"$'\n'
done < <(docker images --format '{{.Repository}}' 2>/dev/null | sort -u)

# --- Report -----------------------------------------------------------------

report() {
  local title="$1" body="$2"
  [ -z "$(sed '/^$/d' <<<"$body")" ] && return
  echo "$title"
  sed '/^$/d' <<<"$body" | awk -F'|' '{printf "  %-52s %s\n", $1, ($3 != "" ? $3 : $2)}'
  echo
}

report "Orphaned containers (project gone from disk):"     "$ORPHAN_CONTAINERS"
report "Orphaned cache volumes (safe — regenerates):"      "$ORPHAN_VOLUMES"
report "Orphaned images (rebuild on next up):"             "$ORPHAN_IMAGES"
report "Orphaned DATA volumes (--prune-all to remove):"    "$ORPHAN_DATA_VOLUMES"
report "Anonymous volumes (review by hand, never auto-removed):" "$UNLABELLED_VOLUMES"

if [ -z "$(sed '/^$/d' <<<"$ORPHAN_CONTAINERS$ORPHAN_VOLUMES$ORPHAN_IMAGES$ORPHAN_DATA_VOLUMES")" ]; then
  echo "No orphans found."
  exit 0
fi

if [ "$MODE" = "dry" ]; then
  echo "Dry run — nothing removed. Re-run with --prune (or --prune-all to include data volumes)."
  exit 0
fi

# --- Prune ------------------------------------------------------------------
# Containers first: an image cannot be removed while a container references it.

while IFS='|' read -r cid cname _; do
  [ -n "$cid" ] && { echo "rm container  $cname"; docker rm -f "$cid" >/dev/null 2>&1; }
done < <(sed '/^$/d' <<<"$ORPHAN_CONTAINERS")

while IFS='|' read -r vol _; do
  [ -n "$vol" ] && { echo "rm volume     $vol"; docker volume rm "$vol" >/dev/null 2>&1; }
done < <(sed '/^$/d' <<<"$ORPHAN_VOLUMES")

while IFS='|' read -r img _; do
  [ -n "$img" ] && { echo "rmi image     $img"; docker rmi "$img" >/dev/null 2>&1; }
done < <(sed '/^$/d' <<<"$ORPHAN_IMAGES")

if [ "$MODE" = "prune-all" ]; then
  while IFS='|' read -r vol _; do
    [ -n "$vol" ] && { echo "rm DATA vol   $vol"; docker volume rm "$vol" >/dev/null 2>&1; }
  done < <(sed '/^$/d' <<<"$ORPHAN_DATA_VOLUMES")
fi

echo
echo "Done."
