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
LOG_DIR="$HOME/Library/Logs"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_LABEL="com.fra.securitycheck"
LAUNCH_AGENT_FILE="$LAUNCH_AGENTS_DIR/${LAUNCH_AGENT_LABEL}.plist"
CLI_DIR="${CLI_DIR:-/usr/local/bin}"

info() { echo "[INFO] $*"; }
ok() { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[ERROR] $*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

install_cli_script() {
  local target="$1"
  local source_file="$2"

  if [[ -w "$CLI_DIR" ]] || [[ ! -e "$CLI_DIR" && -w "$(dirname "$CLI_DIR")" ]]; then
    mkdir -p "$CLI_DIR"
    install -m 0755 "$source_file" "$target"
  else
    sudo mkdir -p "$CLI_DIR"
    sudo install -m 0755 "$source_file" "$target"
  fi
}

info "Installing Mac Security Monitor..."

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer supports macOS only."

require_cmd launchctl
require_cmd osascript
require_cmd install

info "Creating runtime directories..."
mkdir -p "$BIN_DIR" "$DOC_DIR" "$BASELINE_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"
ok "Directories ready."

info "Installing scripts..."
install -m 0755 "$PROJECT_ROOT/src/maccheck" "$BIN_DIR/maccheck"
install -m 0755 "$PROJECT_ROOT/src/maccheck-alert" "$BIN_DIR/maccheck-alert"
install -m 0755 "$PROJECT_ROOT/src/securitycheck-status" "$BIN_DIR/securitycheck-status"
ok "Scripts installed."

info "Installing documentation..."
install -m 0644 "$PROJECT_ROOT/docs/README.md" "$DOC_DIR/README.md"
ok "Documentation installed."

info "Generating baseline..."
"$BIN_DIR/maccheck" >"$BASELINE_DIR/current"
ok "Baseline generated at $BASELINE_DIR/current"

info "Installing LaunchAgent..."
sed \
  -e "s|__BASE_DIR__|$BASE_DIR|g" \
  -e "s|__HOME_DIR__|$HOME|g" \
  "$PROJECT_ROOT/launchd/com.fra.securitycheck.plist" >"$LAUNCH_AGENT_FILE"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_FILE"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
ok "LaunchAgent installed and loaded."

info "Installing CLI commands..."
status_wrapper="$(mktemp -t mac-security-monitor-status.XXXXXX)"
update_wrapper="$(mktemp -t mac-security-monitor-update.XXXXXX)"

cat >"$status_wrapper" <<EOF_STATUS
#!/bin/zsh
BASE_DIR="$BASE_DIR" exec "$BIN_DIR/securitycheck-status"
EOF_STATUS

cat >"$update_wrapper" <<EOF_UPDATE
#!/bin/zsh
set -euo pipefail
BASE_DIR="$BASE_DIR"
"$BIN_DIR/maccheck" > "$BASELINE_DIR/current"
exec "$CLI_DIR/security-monitor"
EOF_UPDATE

install_cli_script "$CLI_DIR/security-monitor" "$status_wrapper"
install_cli_script "$CLI_DIR/security-monitor-update" "$update_wrapper"
rm -f "$status_wrapper" "$update_wrapper"
ok "CLI commands installed in $CLI_DIR"

info "Verifying installation..."
[[ -x "$BIN_DIR/maccheck" ]] || fail "maccheck is not executable."
[[ -x "$BIN_DIR/maccheck-alert" ]] || fail "maccheck-alert is not executable."
[[ -f "$BASELINE_DIR/current" ]] || fail "Baseline file missing after install."
[[ -f "$LAUNCH_AGENT_FILE" ]] || fail "LaunchAgent plist missing after install."

if launchctl list | grep -q "$LAUNCH_AGENT_LABEL"; then
  ok "LaunchAgent is active."
else
  warn "LaunchAgent not visible in launchctl list; re-login may be required."
fi

ok "Installation complete."
echo
echo "Try: security-monitor"
echo "Update baseline: security-monitor-update"
