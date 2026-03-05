#!/bin/zsh

# Mac Security Monitor installer
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
BIN_DIR="$BASE_DIR/bin"
DOC_DIR="$BASE_DIR/docs"
BASELINE_DIR="$BASE_DIR/baseline"
BASELINE_FILE="$BASELINE_DIR/current"
LOG_DIR="$BASE_DIR/logs"
STATE_DIR="$BASE_DIR/state"
CONFIG_FILE="$BASE_DIR/config"
MONITOR_LOG="$LOG_DIR/monitor.log"
VERSION_SRC="$PROJECT_ROOT/VERSION"
VERSION_DST="$BASE_DIR/VERSION"

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_LABEL="com.frapo78.securitycheck"
LAUNCH_AGENT_FILE="$LAUNCH_AGENTS_DIR/${LAUNCH_AGENT_LABEL}.plist"

CLI_DIR="${CLI_DIR:-}"
CLI_STATUS=""
CLI_UPDATE=""

MSM_INSTALL_NONINTERACTIVE="${MSM_INSTALL_NONINTERACTIVE:-0}"
MSM_AUTO_UPDATE_CHECK="${MSM_AUTO_UPDATE_CHECK:-false}"
MSM_PRESERVE_BASELINE="${MSM_PRESERVE_BASELINE:-1}"

info() { echo "[INFO] $*"; }
ok() { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[ERROR] $*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

log_event() {
  local message="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$MONITOR_LOG" 2>/dev/null || true
}

write_file() {
  local source_file="$1"
  local destination_file="$2"
  local mode="$3"
  install -m "$mode" "$source_file" "$destination_file"
}

detect_cli_dir() {
  if [[ -n "$CLI_DIR" ]]; then
    return 0
  fi

  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    CLI_DIR="$HOMEBREW_PREFIX/bin"
    info "Detected Homebrew prefix from environment: $HOMEBREW_PREFIX"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$brew_prefix" ]]; then
      CLI_DIR="$brew_prefix/bin"
      info "Detected Homebrew installation: $brew_prefix"
      return 0
    fi
  fi

  CLI_DIR="/usr/local/bin"
}

create_symlink() {
  local source_path="$1"
  local target_path="$2"

  if [[ -w "$CLI_DIR" ]] || [[ ! -e "$CLI_DIR" && -w "$(dirname "$CLI_DIR")" ]]; then
    mkdir -p "$CLI_DIR"
    ln -sf "$source_path" "$target_path"
  else
    sudo mkdir -p "$CLI_DIR"
    sudo ln -sf "$source_path" "$target_path"
  fi
}

verify_path_safety() {
  [[ "$BASE_DIR" == "$HOME/.mac-security-monitor" ]] || warn "Using custom BASE_DIR: $BASE_DIR"
  [[ "$BASE_DIR" != "/" && "$BASE_DIR" != "$HOME" && -n "$BASE_DIR" ]] || fail "Unsafe BASE_DIR: $BASE_DIR"
}

write_update_config() {
  local enabled="$1"
  cat >"$CONFIG_FILE" <<CONFIG
# Mac Security Monitor configuration
# Author: Francesco Poltero
AUTO_UPDATE_CHECK=$enabled
CONFIG
}

configure_auto_update_check() {
  if [[ -f "$CONFIG_FILE" ]]; then
    info "Keeping existing update-check configuration at $CONFIG_FILE"
    return 0
  fi

  local enabled="false"

  if [[ "$MSM_INSTALL_NONINTERACTIVE" == "1" ]]; then
    if [[ "$MSM_AUTO_UPDATE_CHECK" == "true" ]]; then
      enabled="true"
    fi
    write_update_config "$enabled"
    ok "Automatic update check configured: $enabled"
    return 0
  fi

  if [[ -t 0 ]]; then
    printf 'Enable automatic update checks? (recommended) [y/N] '
    local answer=""
    read -r answer || true
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      enabled="true"
    fi
  fi

  write_update_config "$enabled"
  ok "Automatic update check configured: $enabled"
}

info "Installing Mac Security Monitor..."

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer supports macOS only."

require_cmd launchctl
require_cmd osascript
require_cmd install
require_cmd sed
require_cmd ln
require_cmd plutil
verify_path_safety

[[ -f "$VERSION_SRC" ]] || fail "Missing VERSION file at repository root."

detect_cli_dir
CLI_STATUS="$CLI_DIR/security-monitor"
CLI_UPDATE="$CLI_DIR/security-monitor-update"
info "CLI directory: $CLI_DIR"

info "Creating runtime directories..."
mkdir -p "$BIN_DIR" "$DOC_DIR" "$BASELINE_DIR" "$LOG_DIR" "$STATE_DIR" "$LAUNCH_AGENTS_DIR"
ok "Directories ready."

info "Installing scripts..."
write_file "$PROJECT_ROOT/src/maccheck" "$BIN_DIR/maccheck" 0755
write_file "$PROJECT_ROOT/src/maccheck-alert" "$BIN_DIR/maccheck-alert" 0755
write_file "$PROJECT_ROOT/src/securitycheck-status" "$BIN_DIR/securitycheck-status" 0755
write_file "$PROJECT_ROOT/src/security-monitor-update" "$BIN_DIR/security-monitor-update" 0755
write_file "$PROJECT_ROOT/src/reinstall.sh" "$BIN_DIR/reinstall.sh" 0755
write_file "$PROJECT_ROOT/src/update-check.sh" "$BIN_DIR/update-check.sh" 0755
write_file "$PROJECT_ROOT/src/update-install.sh" "$BIN_DIR/update-install.sh" 0755
ok "Scripts installed."

info "Installing documentation and version metadata..."
write_file "$PROJECT_ROOT/docs/README.md" "$DOC_DIR/README.md" 0644
write_file "$VERSION_SRC" "$VERSION_DST" 0644
ok "Documentation and version installed."

configure_auto_update_check

if [[ -f "$BASELINE_FILE" && "$MSM_PRESERVE_BASELINE" == "1" ]]; then
  info "Keeping existing baseline at $BASELINE_FILE"
else
  info "Generating baseline..."
  "$BIN_DIR/maccheck" >"$BASELINE_FILE"
  log_event "Baseline created during installation."
  ok "Baseline generated at $BASELINE_FILE"
fi

info "Installing LaunchAgent..."
tmp_plist=""
cleanup() {
  if [[ -n "$tmp_plist" ]]; then
    rm -f "$tmp_plist"
  fi
}
trap cleanup EXIT
tmp_plist="$(mktemp -t mac-security-monitor-plist.XXXXXX)"

sed -e "s|__BASE_DIR__|$BASE_DIR|g" "$PROJECT_ROOT/launchd/com.frapo78.securitycheck.plist" >"$tmp_plist"

plutil -lint "$tmp_plist" >/dev/null || fail "Generated LaunchAgent plist is invalid."
cp -f "$tmp_plist" "$LAUNCH_AGENT_FILE"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_FILE"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
log_event "LaunchAgent installed and started."
ok "LaunchAgent installed and loaded."

info "Installing CLI commands..."
create_symlink "$BIN_DIR/securitycheck-status" "$CLI_STATUS"
create_symlink "$BIN_DIR/security-monitor-update" "$CLI_UPDATE"
ok "CLI commands installed in $CLI_DIR"

info "Verifying installation..."
[[ -x "$BIN_DIR/maccheck" ]] || fail "maccheck is not executable."
[[ -x "$BIN_DIR/maccheck-alert" ]] || fail "maccheck-alert is not executable."
[[ -x "$BIN_DIR/securitycheck-status" ]] || fail "securitycheck-status is not executable."
[[ -x "$BIN_DIR/security-monitor-update" ]] || fail "security-monitor-update is not executable."
[[ -x "$BIN_DIR/reinstall.sh" ]] || fail "reinstall.sh is not executable."
[[ -x "$BIN_DIR/update-check.sh" ]] || fail "update-check.sh is not executable."
[[ -x "$BIN_DIR/update-install.sh" ]] || fail "update-install.sh is not executable."
[[ -f "$BASELINE_FILE" ]] || fail "Baseline file missing after install."
[[ -f "$LAUNCH_AGENT_FILE" ]] || fail "LaunchAgent plist missing after install."
[[ -f "$CONFIG_FILE" ]] || fail "Configuration file missing after install."

if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
  ok "LaunchAgent is active."
else
  warn "LaunchAgent not visible via launchctl print; re-login may be required."
fi

log_event "Installation completed successfully."
ok "Installation complete."
echo
echo "Try: security-monitor"
echo "Update baseline: security-monitor update-baseline"
echo "Version: security-monitor --version"
echo "Check updates: security-monitor check-update"
echo "Upgrade: security-monitor upgrade"
echo "Reinstall: security-monitor reinstall"
echo "Log: security-monitor log"
echo "Last change: security-monitor last-change"
