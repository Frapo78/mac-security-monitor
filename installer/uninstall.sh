#!/bin/zsh

# Mac Security Monitor uninstaller
# Author: Francesco Poltero

set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
BIN_DIR="$BASE_DIR/bin"
LOG_DIR="$BASE_DIR/logs"
MONITOR_LOG="$LOG_DIR/monitor.log"

LAUNCH_AGENT_LABEL="com.frapo78.securitycheck"
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"

CLI_DIR="${CLI_DIR:-/usr/local/bin}"
CLI_STATUS="$CLI_DIR/security-monitor"
CLI_UPDATE="$CLI_DIR/security-monitor-update"

info() { echo "[INFO] $*"; }
ok() { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[ERROR] $*"; exit 1; }

log_event() {
  local message="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$MONITOR_LOG" 2>/dev/null || true
}

verify_base_dir() {
  [[ "$BASE_DIR" != "/" && "$BASE_DIR" != "$HOME" && -n "$BASE_DIR" ]] || fail "Unsafe BASE_DIR: $BASE_DIR"
}

safe_remove_path() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    if [[ -d "$path" && ! -L "$path" ]]; then
      rm -rf "$path"
    else
      rm -f "$path"
    fi
    ok "Removed $path"
  fi
}

safe_remove_cli_path() {
  local path="$1"
  local expected_target="$2"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return 0
  fi

  if [[ -L "$path" ]]; then
    local resolved
    resolved="$(readlink "$path")"
    if [[ "$resolved" == "$expected_target" ]]; then
      if [[ -w "$path" || -w "$(dirname "$path")" ]]; then
        rm -f "$path"
      else
        sudo rm -f "$path"
      fi
      ok "Removed $path"
      return 0
    fi

    warn "Skipped $path: symlink does not target $expected_target"
    return 0
  fi

  if grep -q "mac-security-monitor" "$path" 2>/dev/null; then
    if [[ -w "$path" || -w "$(dirname "$path")" ]]; then
      rm -f "$path"
    else
      sudo rm -f "$path"
    fi
    ok "Removed legacy wrapper $path"
  else
    warn "Skipped $path: not recognized as Mac Security Monitor artifact"
  fi
}

verify_base_dir

info "Removing Mac Security Monitor..."

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
ok "LaunchAgent stopped (if active)."

safe_remove_path "$LAUNCH_AGENT_FILE"

safe_remove_cli_path "$CLI_STATUS" "$BIN_DIR/securitycheck-status"
safe_remove_cli_path "$CLI_UPDATE" "$BIN_DIR/security-monitor-update"

if [[ -d "$BASE_DIR" ]]; then
  log_event "Uninstall started."
  safe_remove_path "$BASE_DIR"
else
  warn "Base directory not found: $BASE_DIR"
fi

ok "Uninstall complete."
