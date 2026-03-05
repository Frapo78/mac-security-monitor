#!/bin/zsh

# Mac Security Monitor
# Author: Francesco Poltero
#
# Reinstalls Mac Security Monitor from the official GitHub repository,
# preserving user baseline, logs, and configuration.

set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
BIN_DIR="$BASE_DIR/bin"
BASELINE_FILE="$BASE_DIR/baseline/current"
CONFIG_FILE="$BASE_DIR/config"
LOG_DIR="$BASE_DIR/logs"
MONITOR_LOG="$LOG_DIR/monitor.log"

LAUNCH_AGENT_LABEL="com.frapo78.securitycheck"
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"

REPO_ARCHIVE_URL="${MSM_REPO_ARCHIVE_URL:-https://codeload.github.com/Frapo78/mac-security-monitor/tar.gz/refs/heads/main}"
CURL_MAX_TIME="${MSM_CURL_MAX_TIME:-30}"

info() { echo "[INFO] $*"; }
ok() { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[ERROR] $*"; exit 1; }

log_event() {
  local message="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$MONITOR_LOG" 2>/dev/null || true
}

verify_installation() {
  [[ -x "$BIN_DIR/maccheck" ]] || fail "maccheck is missing after reinstall."
  [[ -x "$BIN_DIR/maccheck-alert" ]] || fail "maccheck-alert is missing after reinstall."
  [[ -x "$BIN_DIR/securitycheck-status" ]] || fail "securitycheck-status is missing after reinstall."
  [[ -f "$BASE_DIR/VERSION" ]] || fail "VERSION file is missing after reinstall."
}

command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v tar >/dev/null 2>&1 || fail "tar is required"
command -v launchctl >/dev/null 2>&1 || fail "launchctl is required"

echo "Mac Security Monitor"
echo "Reinstalling from GitHub..."

tmp_dir="$(mktemp -d -t mac-security-monitor-reinstall.XXXXXX)"
archive_file="$tmp_dir/repository.tar.gz"
extract_dir="$tmp_dir/extracted"
backup_dir="$tmp_dir/backup"
mkdir -p "$extract_dir" "$backup_dir"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo
echo "Preserving configuration..."
if [[ -f "$BASELINE_FILE" ]]; then
  mkdir -p "$backup_dir/baseline"
  cp -f "$BASELINE_FILE" "$backup_dir/baseline/current"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  cp -f "$CONFIG_FILE" "$backup_dir/config"
fi

if [[ -d "$LOG_DIR" ]]; then
  mkdir -p "$backup_dir/logs"
  cp -R "$LOG_DIR"/. "$backup_dir/logs"/ 2>/dev/null || true
fi

echo "Downloading latest version..."
if ! curl -fsSL --max-time "$CURL_MAX_TIME" "$REPO_ARCHIVE_URL" -o "$archive_file"; then
  fail "Failed to download repository archive from GitHub."
fi

echo "Running installer..."
if ! tar -xzf "$archive_file" -C "$extract_dir"; then
  fail "Failed to extract repository archive."
fi

source_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$source_dir" ]] || fail "Invalid archive layout."

[[ -x "$source_dir/installer/install.sh" ]] || fail "Installer not found in downloaded package."

BASE_DIR="$BASE_DIR" MSM_INSTALL_NONINTERACTIVE=1 MSM_PRESERVE_BASELINE=1 "$source_dir/installer/install.sh"

if [[ -f "$backup_dir/baseline/current" ]]; then
  mkdir -p "$BASE_DIR/baseline"
  cp -f "$backup_dir/baseline/current" "$BASELINE_FILE"
fi

if [[ -f "$backup_dir/config" ]]; then
  cp -f "$backup_dir/config" "$CONFIG_FILE"
fi

if [[ -d "$backup_dir/logs" ]]; then
  mkdir -p "$LOG_DIR"
  cp -R "$backup_dir/logs"/. "$LOG_DIR"/ 2>/dev/null || true
fi

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_FILE"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true

verify_installation
log_event "Reinstallation completed successfully from GitHub."

echo
echo "Reinstallation complete."
