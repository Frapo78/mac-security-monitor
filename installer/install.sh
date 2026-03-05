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
MONITOR_LOG="$LOG_DIR/monitor.log"
VERSION_SRC="$PROJECT_ROOT/VERSION"
VERSION_DST="$BASE_DIR/VERSION"

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_LABEL="com.frapo78.securitycheck"
LAUNCH_AGENT_FILE="$LAUNCH_AGENTS_DIR/${LAUNCH_AGENT_LABEL}.plist"

CLI_DIR="${CLI_DIR:-/usr/local/bin}"
CLI_STATUS="$CLI_DIR/security-monitor"
CLI_UPDATE="$CLI_DIR/security-monitor-update"

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

info "Creating runtime directories..."
mkdir -p "$BIN_DIR" "$DOC_DIR" "$BASELINE_DIR" "$LOG_DIR" "$STATE_DIR" "$LAUNCH_AGENTS_DIR"
ok "Directories ready."

info "Installing scripts..."
write_file "$PROJECT_ROOT/src/maccheck" "$BIN_DIR/maccheck" 0755
write_file "$PROJECT_ROOT/src/maccheck-alert" "$BIN_DIR/maccheck-alert" 0755
write_file "$PROJECT_ROOT/src/securitycheck-status" "$BIN_DIR/securitycheck-status" 0755
write_file "$PROJECT_ROOT/src/security-monitor-update" "$BIN_DIR/security-monitor-update" 0755
ok "Scripts installed."

info "Installing documentation and version metadata..."
write_file "$PROJECT_ROOT/docs/README.md" "$DOC_DIR/README.md" 0644
write_file "$VERSION_SRC" "$VERSION_DST" 0644
ok "Documentation and version installed."

info "Generating baseline..."
"$BIN_DIR/maccheck" >"$BASELINE_FILE"
log_event "Baseline created during installation."
ok "Baseline generated at $BASELINE_FILE"

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
[[ -f "$BASELINE_FILE" ]] || fail "Baseline file missing after install."
[[ -f "$LAUNCH_AGENT_FILE" ]] || fail "LaunchAgent plist missing after install."

if launchctl list | grep -q "$LAUNCH_AGENT_LABEL"; then
  ok "LaunchAgent is active."
else
  warn "LaunchAgent not visible in launchctl list; re-login may be required."
fi

log_event "Installation completed successfully."
ok "Installation complete."
echo
echo "Try: security-monitor"
echo "Update baseline: security-monitor-update"
echo "Version: security-monitor --version"
echo "Log: security-monitor log"
echo "Last change: security-monitor last-change"
