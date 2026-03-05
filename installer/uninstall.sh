#!/bin/zsh

# Mac Security Monitor uninstaller
# Author: Francesco Poltero

set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
LAUNCH_AGENT_LABEL="com.fra.securitycheck"
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"
CLI_DIR="${CLI_DIR:-/usr/local/bin}"
CLI_STATUS="$CLI_DIR/security-monitor"
CLI_UPDATE="$CLI_DIR/security-monitor-update"

info() { echo "[INFO] $*"; }
ok() { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }

remove_path() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    rm -rf "$path"
    ok "Removed $path"
  fi
}

safe_remove_cli() {
  local path="$1"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return 0
  fi

  if [[ -w "$path" || -w "$(dirname "$path")" ]]; then
    rm -f "$path"
  else
    sudo rm -f "$path"
  fi

  ok "Removed $path"
}

if [[ "${BASE_DIR}" == "/" || "${BASE_DIR}" == "$HOME" || "${BASE_DIR}" == "" ]]; then
  echo "[ERROR] Refusing to remove unsafe BASE_DIR: $BASE_DIR"
  exit 1
fi

info "Removing Mac Security Monitor..."

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
ok "LaunchAgent stopped (if it was active)."

remove_path "$LAUNCH_AGENT_FILE"

if [[ -d "$BASE_DIR" ]]; then
  remove_path "$BASE_DIR"
else
  warn "Base directory not found: $BASE_DIR"
fi

safe_remove_cli "$CLI_STATUS"
safe_remove_cli "$CLI_UPDATE"

ok "Uninstall complete."
