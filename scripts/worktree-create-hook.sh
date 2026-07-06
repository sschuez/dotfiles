#!/bin/bash
# Claude Code WorktreeCreate hook
#
# Reads {"name": "...", "cwd": "...", ...} JSON from stdin, creates a git
# worktree under <repo>/.claude/worktrees/<name>, prints its absolute path to
# stdout (the ONLY stdout output — Claude Code reads it), then runs
# best-effort project setup. Setup failures never break worktree creation.
#
# Layered design — what runs for every repo vs. per convention:
#
#   Always (any repo):
#     - git worktree on branch "worktree-<name>", based off the current
#       branch (override the base with WORKTREE_BASE=<branch>)
#     - .env copied from the main checkout, or from
#       .env.example/.env.template/.env.sample as fallback
#     - bin/worktree-setup executed if the repo provides one (see below)
#
#   Docker repos (docker-compose.yml / compose.yml / bin/docker-env):
#     Path A — repo has bin/docker-env: delegate to
#       `bin/docker-env setup <name> <port>`; the repo owns ports,
#       COMPOSE_PROJECT_NAME and DB names (e.g. submissio).
#     Path B — compose file only:
#       * PREFERRED: compose uses ${APP_PORT:-3000}-style vars -> unique
#         APP_PORT / DEBUG_PORT / CHROME_PORT are written to the worktree
#         .env and compose picks them up (e.g. gym)
#       * legacy: literal ports -> the canonical "3000:3000" / "1234:1234" /
#         "7900:7900" mappings are rewritten in place
#       Either way COMPOSE_PROJECT_NAME=<repo>_<name> is pinned in .env so
#       containers/volumes can't collide with the main checkout or with a
#       same-named worktree in another repo — and so the cleanup hook can
#       find the resources later.
#
#   Rails repos: master.key, config/credentials/*.key, credentials.yml.enc
#     and database.yml copied from the main checkout; RAILS_MASTER_KEY
#     appended to the worktree .env.
#
# Per-repo extension point — bin/worktree-setup:
#   Drop an executable bin/worktree-setup into a repo for project-specific
#   setup (seed data, node_modules linking, extra credentials, ...). It runs
#   LAST, from inside the new worktree, with these variables exported:
#     WORKTREE_DIR   absolute path of the new worktree
#     MAIN_DIR       absolute path of the main checkout
#     WORKTREE_NAME  the worktree's name
#     APP_PORT       allocated app port (empty for non-Docker repos)
#
# Adopting this in a new repo needs only ONE thing: parameterize the compose
# ports, e.g.  - "${APP_PORT:-3000}:3000". Everything else is optional.

# --- Phase 1: Parse input and create worktree (must succeed) ---

INPUT=$(cat)

# Extract fields (jq preferred, sed fallback)
if command -v jq &>/dev/null; then
  NAME=$(echo "$INPUT" | jq -r '.name // empty')
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
else
  NAME=$(echo "$INPUT" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  CWD=$(echo "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -z "$NAME" ] || [ -z "$CWD" ]; then
  echo "Error: missing name or cwd in hook input" >&2
  exit 1
fi

WORKTREE_DIR="${CWD}/.claude/worktrees/${NAME}"
BRANCH_NAME="worktree-${NAME}"

# Ensure parent directory exists
mkdir -p "$(dirname "$WORKTREE_DIR")"

# Branch from current branch (override with WORKTREE_BASE=<branch> if needed)
BASE_BRANCH="${WORKTREE_BASE:-$(git -C "$CWD" branch --show-current 2>/dev/null || echo "HEAD")}"

# Create git worktree
if ! git -C "$CWD" worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH" >&2; then
  # Branch might already exist, try without -b
  if ! git -C "$CWD" worktree add "$WORKTREE_DIR" "$BRANCH_NAME" >&2; then
    echo "Error: failed to create git worktree" >&2
    exit 1
  fi
fi

# Print absolute path to stdout (this is the ONLY stdout output)
echo "$WORKTREE_DIR"

# --- Phase 2: Best-effort project setup (failures are non-fatal) ---
set +e

log() { echo "[worktree-hook] $*" >&2; }

# Detect project type
IS_RAILS=false
IS_DOCKER=false
COMPOSE_FILE=""

if [ -f "${CWD}/config/application.rb" ]; then
  IS_RAILS=true
elif [ -f "${CWD}/Gemfile" ] && grep -q "rails" "${CWD}/Gemfile" 2>/dev/null; then
  IS_RAILS=true
fi

if [ -f "${CWD}/docker-compose.yml" ]; then
  IS_DOCKER=true
  COMPOSE_FILE="docker-compose.yml"
elif [ -f "${CWD}/compose.yml" ]; then
  IS_DOCKER=true
  COMPOSE_FILE="compose.yml"
elif [ -f "${CWD}/bin/docker-env" ]; then
  IS_DOCKER=true
fi

# No early exit: .env setup and bin/worktree-setup below run for ANY repo;
# the Docker/Rails sections guard themselves.
log "Project detected: rails=$IS_RAILS docker=$IS_DOCKER"

# In-place sed that works with both BSD (macOS) and GNU sed
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# --- Port allocation helpers ---

# Collect ports already claimed by sibling worktrees (even if stopped).
# Harvests every *_PORT= var from their .env and the host side of every
# literal "HOST:CONTAINER" mapping in their compose files.
collect_claimed_ports() {
  local worktrees_dir="${CWD}/.claude/worktrees"
  [ -d "$worktrees_dir" ] || return

  for wt_dir in "$worktrees_dir"/*/; do
    [ -d "$wt_dir" ] || continue
    # Skip the worktree we're currently creating
    [ "$wt_dir" = "${WORKTREE_DIR}/" ] && continue

    # .env: any FOO_PORT=XXXX
    if [ -f "${wt_dir}.env" ]; then
      grep -E "^[A-Z_]*PORT=[0-9]+$" "${wt_dir}.env" 2>/dev/null | cut -d= -f2
    fi

    # compose files: host side of any literal "XXXX:YYYY" mapping
    for cf in docker-compose.yml compose.yml; do
      if [ -f "${wt_dir}${cf}" ]; then
        grep -oE '"[0-9]+:[0-9]+"' "${wt_dir}${cf}" 2>/dev/null | tr -d '"' | cut -d: -f1
      fi
    done
  done
}

# Build a newline-separated list of all claimed ports (once, before allocation)
CLAIMED_PORTS=$(collect_claimed_ports | sort -u)

is_port_claimed() {
  local port=$1
  echo "$CLAIMED_PORTS" | grep -qx "$port"
}

is_port_in_use() {
  local port=$1
  # Check against ports reserved by sibling worktrees (even if stopped)
  is_port_claimed "$port" && return 0
  # Check ports already allocated earlier in this same run
  echo "$ALLOCATED_PORTS" | grep -qx "$port" && return 0
  # Check live listeners
  docker ps --format "table {{.Ports}}" 2>/dev/null | grep -q ":${port}->" && return 0
  lsof -iTCP:${port} -sTCP:LISTEN &>/dev/null && return 0
  return 1
}

# Ports handed out earlier in this run, so a later allocation can't reuse them.
ALLOCATED_PORTS=""

find_next_port() {
  local port=$1
  local max_attempts=20
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if ! is_port_in_use $port; then
      ALLOCATED_PORTS="${ALLOCATED_PORTS}${port}"$'\n'
      echo $port
      return 0
    fi
    ((port++))
    ((attempt++))
  done
  log "WARN: no free port found in $1-$((port - 1)), falling back to $1 (may conflict)"
  echo $1
  return 1
}

# --- Docker setup ---

if $IS_DOCKER && command -v docker &>/dev/null; then
  APP_PORT=$(find_next_port 3001)
  CLEAN_NAME=$(echo "$NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

  if [ -f "${CWD}/bin/docker-env" ] && [ -f "${WORKTREE_DIR}/bin/docker-env" ]; then
    # Path A: bin/docker-env exists — the repo's script owns ports,
    # COMPOSE_PROJECT_NAME and DB names.
    log "Running bin/docker-env setup $CLEAN_NAME $APP_PORT"
    (cd "$WORKTREE_DIR" && bin/docker-env setup "$CLEAN_NAME" "$APP_PORT") >&2 2>&1 || true

  elif [ -n "$COMPOSE_FILE" ] && [ -f "${WORKTREE_DIR}/${COMPOSE_FILE}" ]; then
    # Path B: compose file only.
    # Allocate each port independently so debug/chrome can't collide with a
    # sibling worktree or the main worktree's defaults (offsets alone don't check).
    DEBUG_PORT=$(find_next_port 1234)
    CHROME_PORT=$(find_next_port 7900)

    if grep -q '${APP_PORT' "${WORKTREE_DIR}/${COMPOSE_FILE}" 2>/dev/null; then
      # Compose uses ${APP_PORT}/${DEBUG_PORT}/${CHROME_PORT} interpolation —
      # write the ports to .env and let compose read them (preferred).
      log "Writing ports to .env: app=$APP_PORT debug=$DEBUG_PORT chrome=$CHROME_PORT"
      {
        echo "# Ports (auto-assigned by worktree hook)"
        echo "APP_PORT=$APP_PORT"
        echo "DEBUG_PORT=$DEBUG_PORT"
        echo "CHROME_PORT=$CHROME_PORT"
      } >>"${WORKTREE_DIR}/.env"
    else
      # Literal ports — rewrite the canonical mappings in place (legacy).
      log "Rewriting ports in $COMPOSE_FILE: app=$APP_PORT debug=$DEBUG_PORT chrome=$CHROME_PORT"
      sed_inplace \
        -e "s/\"3000:3000\"/\"$APP_PORT:3000\"/g" \
        -e "s/\"1234:1234\"/\"$DEBUG_PORT:1234\"/g" \
        -e "s/\"7900:7900\"/\"$CHROME_PORT:7900\"/g" \
        "${WORKTREE_DIR}/${COMPOSE_FILE}" 2>/dev/null || true
    fi

    # Pin a unique compose project name so containers/volumes can't collide
    # with the main checkout (dir-basename default) or with a same-named
    # worktree in another repo — and so the cleanup hook can find them
    # (it reads COMPOSE_PROJECT_NAME from this .env).
    if ! grep -q "^COMPOSE_PROJECT_NAME=" "${WORKTREE_DIR}/.env" 2>/dev/null; then
      PROJECT_NAME=$(git -C "$CWD" remote get-url origin 2>/dev/null | sed -n 's#.*/\([^/]*\)\.git$#\1#p' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
      [ -z "$PROJECT_NAME" ] && PROJECT_NAME=$(basename "$CWD" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
      PROJECT_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-z0-9_]/_/g')
      COMPOSE_PROJECT="${PROJECT_NAME}_$(echo "$CLEAN_NAME" | tr '-' '_')"
      echo "COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT" >>"${WORKTREE_DIR}/.env"
      log "Pinned COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT"
    fi
  fi
fi

# --- .env setup ---

MAIN_ENV="${CWD}/.env"
WT_ENV="${WORKTREE_DIR}/.env"

if [ -f "$WT_ENV" ] && [ -f "$MAIN_ENV" ]; then
  # Worktree .env already exists (docker-env or port allocation above) —
  # merge main's vars, EXCLUDING anything worktree-specific: the allocated
  # ports and compose/db identity must not be overridden by main's values
  # (with duplicate keys, the later occurrence wins).
  log "Merging main .env into worktree .env"
  {
    echo ""
    echo "# Variables from main worktree"
    grep -vE "^(COMPOSE_PROJECT_NAME|POSTGRES_DB|APP_PORT|DEBUG_PORT|CHROME_PORT)=|^#|^$" "$MAIN_ENV" 2>/dev/null || true
  } >>"$WT_ENV"
elif [ ! -f "$WT_ENV" ] && [ -f "$MAIN_ENV" ]; then
  log "Copying .env from main worktree"
  cp "$MAIN_ENV" "$WT_ENV"
elif [ ! -f "$WT_ENV" ]; then
  # Fall back to template files
  for tmpl in .env.example .env.template .env.sample; do
    if [ -f "${CWD}/${tmpl}" ]; then
      log "Copying $tmpl as .env"
      cp "${CWD}/${tmpl}" "$WT_ENV"
      break
    fi
  done
fi

# --- Rails credentials ---

if $IS_RAILS && [ -f "${CWD}/config/master.key" ]; then
  log "Copying Rails credentials"
  mkdir -p "${WORKTREE_DIR}/config"

  # master.key
  cp "${CWD}/config/master.key" "${WORKTREE_DIR}/config/master.key"
  chmod 600 "${WORKTREE_DIR}/config/master.key"

  # Per-environment keys (development.key, production.key, testing.key, etc.)
  if [ -d "${CWD}/config/credentials" ]; then
    mkdir -p "${WORKTREE_DIR}/config/credentials"
    for keyfile in "${CWD}"/config/credentials/*.key; do
      [ -f "$keyfile" ] || continue
      dest="${WORKTREE_DIR}/config/credentials/$(basename "$keyfile")"
      cp "$keyfile" "$dest"
      chmod 600 "$dest"
      log "Copied credentials/$(basename "$keyfile")"
    done
  fi

  # credentials.yml.enc
  if [ -f "${CWD}/config/credentials.yml.enc" ] && [ ! -f "${WORKTREE_DIR}/config/credentials.yml.enc" ]; then
    cp "${CWD}/config/credentials.yml.enc" "${WORKTREE_DIR}/config/credentials.yml.enc"
  fi

  # database.yml
  if [ -f "${CWD}/config/database.yml" ] && [ ! -f "${WORKTREE_DIR}/config/database.yml" ]; then
    cp "${CWD}/config/database.yml" "${WORKTREE_DIR}/config/database.yml"
  fi

  # Add RAILS_MASTER_KEY to .env if not present
  if [ -f "$WT_ENV" ] && ! grep -q "^RAILS_MASTER_KEY=" "$WT_ENV" 2>/dev/null; then
    MASTER_KEY=$(cat "${CWD}/config/master.key")
    {
      echo ""
      echo "# Rails master key (auto-added by worktree hook)"
      echo "RAILS_MASTER_KEY=$MASTER_KEY"
    } >>"$WT_ENV"
    log "Added RAILS_MASTER_KEY to .env"
  fi
fi

# --- Bundler setup ---
# .bundle/ and vendor/bundle/ are gitignored, so worktrees don't get them.
# Point Bundler at the main repo's vendor/bundle via absolute path so linters
# and other bundle exec commands use the same gem set.

if [ -f "${CWD}/.bundle/config" ] && [ -d "${CWD}/vendor/bundle" ]; then
  mkdir -p "${WORKTREE_DIR}/.bundle"
  cat > "${WORKTREE_DIR}/.bundle/config" <<BUNDLEEOF
---
BUNDLE_PATH: "${CWD}/vendor/bundle"
BUNDLEEOF
  log "Created .bundle/config pointing to main repo's vendor/bundle"
fi

# --- RuboCop hidden-path workaround ---
# When cwd is under a dot-directory, RuboCop's hidden_path? check breaks
# AllCops.Exclude. Patch bin/rubocop to pass explicit targets instead of ".".

if [ -f "${WORKTREE_DIR}/bin/rubocop" ] && ! grep -q "Worktree fix" "${WORKTREE_DIR}/bin/rubocop" 2>/dev/null; then
  ruby -e '
    content = File.read(ARGV[0])
    fix = <<~RUBY

      # Worktree fix: when cwd is under a dot-directory (e.g. .claude/worktrees/),
      # RuboCop'\''s hidden_path? check breaks AllCops.Exclude. Pass explicit targets
      # so the exclude patterns work normally. Only activates when no file arguments
      # are given and cwd contains a hidden path component.
      if ARGV.none? { |arg| !arg.start_with?("-") } && Dir.pwd.split(File::SEPARATOR).any? { |d| d.start_with?(".") && d.length > 1 }
        targets = %w[app config db lib test Gemfile Rakefile config.ru].select { |t| File.exist?(t) }
        ARGV.push(*targets)
      end
    RUBY
    patched = content.sub(/^(load Gem\.bin_path)/, fix + "\n\\1")
    File.write(ARGV[0], patched)
  ' "${WORKTREE_DIR}/bin/rubocop" 2>/dev/null && log "Patched bin/rubocop for hidden-path workaround" || true
fi

# --- mise trust ---
# Worktree copies of mise.toml aren't trusted by default.

if command -v mise &>/dev/null; then
  if [ -f "${WORKTREE_DIR}/mise.toml" ]; then
    mise trust "${WORKTREE_DIR}/mise.toml" 2>/dev/null || true
    log "Trusted mise.toml"
  fi
  if [ -f "${WORKTREE_DIR}/.mise.toml" ]; then
    mise trust "${WORKTREE_DIR}/.mise.toml" 2>/dev/null || true
    log "Trusted .mise.toml"
  fi
fi

# --- Per-repo extension point ---
# If the repo ships an executable bin/worktree-setup, run it LAST from inside
# the new worktree for any project-specific setup the generic hook can't know
# about. See the header of this file for the exported variables.

if [ -x "${WORKTREE_DIR}/bin/worktree-setup" ]; then
  log "Running bin/worktree-setup"
  (
    cd "$WORKTREE_DIR" &&
      WORKTREE_DIR="$WORKTREE_DIR" \
      MAIN_DIR="$CWD" \
      WORKTREE_NAME="$NAME" \
      APP_PORT="${APP_PORT:-}" \
      bin/worktree-setup
  ) >&2 2>&1 || log "bin/worktree-setup failed (non-fatal)"
fi

exit 0
