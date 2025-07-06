#!/bin/bash
set -e

# ======================================================
# cmdy installer
# Author: Joseph Pierce
# Version: 2.0.0
# Date: 2025-07-05
# Description: Install or update cmdy CLI tool
# ======================================================

REPO_URL="https://github.com/jdpierce21/cmdy"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/cmdy"
WRAPPER="$INSTALL_DIR/cmdy"
BINARY="$INSTALL_DIR/cmdy.bin"
VERSION_FILE="$CONFIG_DIR/version.json"

FORCE=false
[[ "$1" == "--force" ]] && FORCE=true

log() { echo "$1"; }
die() { echo "Error: $1" >&2; exit 1; }
ensure_tool() { command -v "$1" >/dev/null || die "$1 not found"; }

ensure_dependencies() {
  for tool in git curl go fzf; do
    ensure_tool "$tool"
  done
}

get_latest_commit() {
  curl -s "https://api.github.com/repos/jdpierce21/cmdy/commits/master" |
    grep '"sha"' | head -1 | cut -d'"' -f4
}

get_installed_commit() {
  [[ -f "$VERSION_FILE" ]] && grep '"build_hash"' "$VERSION_FILE" | cut -d'"' -f4 || echo ""
}

check_version_and_exit_if_current() {
  local installed latest
  installed=$(get_installed_commit)
  latest=$(get_latest_commit)

  if [[ "$installed" == "$latest" ]]; then
    log "Already up-to-date (build: ${installed:0:7})"
    exit 0
  elif [[ -n "$installed" ]]; then
    log "New version available (${installed:0:7} → ${latest:0:7})"
  else
    log "No existing installation found"
  fi
}

build_and_install() {
  local tmp commit now
  tmp=$(mktemp -d)
  git clone --quiet "$REPO_URL" "$tmp"
  cd "$tmp"

  commit=$(git rev-parse HEAD)
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  go build -ldflags="-s -w -X main.BuildVersion=$commit -X main.BuildDate=$now" -o cmdy
  mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"
  mv cmdy "$BINARY"
  chmod +x "$BINARY"

  cat > "$VERSION_FILE" <<EOF
{
  "build_hash": "$commit",
  "build_date": "$now",
  "install_date": "$now"
}
EOF

  if [[ ! -f "$WRAPPER" ]]; then
    cat > "$WRAPPER" <<EOF
#!/bin/bash
cd "\$HOME/.config/cmdy"
exec "$BINARY" "\$@"
EOF
    chmod +x "$WRAPPER"
  fi

  if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
    cp config.yaml "$CONFIG_DIR/config.yaml.new"
    log "Preserved user config, wrote new config to config.yaml.new"
  else
    cp config.yaml "$CONFIG_DIR/config.yaml"
  fi

  if [[ -d "$CONFIG_DIR/scripts" ]]; then
    if [[ -d scripts/examples ]]; then
      cp -r scripts/examples "$CONFIG_DIR/scripts/"
      chmod +x "$CONFIG_DIR/scripts/examples"/*.sh 2>/dev/null || true
    fi
  else
    cp -r scripts "$CONFIG_DIR/"
    chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
  fi

  cd "$HOME"
  rm -rf "$tmp"
}

main() {
  log "Checking for updates..."
  [[ "$FORCE" == false ]] && check_version_and_exit_if_current
  log "Installing dependencies"
  ensure_dependencies
  log "Building from source"
  build_and_install
  log "Installation completed successfully."
}

main "$@"