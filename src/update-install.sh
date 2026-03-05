#!/bin/zsh

# Mac Security Monitor
# Author: Francesco Poltero
#
# Performs a user-confirmed OTA upgrade from the official GitHub repository.

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

ASSUME_YES=0

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[ERROR] $*"; exit 1; }

log_event() {
  local message="$1"
  mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$MONITOR_LOG" 2>/dev/null || true
}

usage() {
  cat <<'USAGE'
Usage:
  update-install.sh
  update-install.sh --yes
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      ASSUME_YES=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

[[ -x "$BIN_DIR/update-check.sh" ]] || fail "Missing update checker: $BIN_DIR/update-check.sh"
command -v curl >/dev/null 2>&1 || fail "curl is required for OTA updates"
command -v tar >/dev/null 2>&1 || fail "tar is required for OTA updates"
command -v launchctl >/dev/null 2>&1 || fail "launchctl is required"

set +e
"$BIN_DIR/update-check.sh" --quiet
check_rc=$?
set -e

case "$check_rc" in
  0)
    echo "Mac Security Monitor is already up to date."
    exit 0
    ;;
  10)
    ;;
  *)
    fail "Could not verify remote version."
    ;;
esac

latest_version="$("$BIN_DIR/update-check.sh" --latest)"

echo "Update available: $latest_version"

if [[ "$ASSUME_YES" != "1" ]]; then
  printf '\nDo you want to update now? [y/N] '
  answer=""
  read -r answer || true
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Update cancelled."
    exit 0
  fi
fi

tmp_dir="$(mktemp -d -t mac-security-monitor-upgrade.XXXXXX)"
archive_file="$tmp_dir/repository.tar.gz"
extract_dir="$tmp_dir/extracted"
backup_dir="$tmp_dir/backup"
mkdir -p "$extract_dir" "$backup_dir"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

info "Downloading latest repository archive..."
if ! curl -fsSL --max-time "$CURL_MAX_TIME" "$REPO_ARCHIVE_URL" -o "$archive_file"; then
  fail "Failed to download update package from official repository."
fi

info "Extracting update package..."
if ! tar -xzf "$archive_file" -C "$extract_dir"; then
  fail "Failed to extract update package."
fi

source_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$source_dir" ]] || fail "Invalid update package layout."

new_version_file="$source_dir/VERSION"
[[ -f "$new_version_file" ]] || fail "Update package does not include VERSION file."

new_version="$(head -n 1 "$new_version_file" | tr -d '[:space:]')"
if [[ "$new_version" != "$latest_version" ]]; then
  fail "VERSION mismatch in downloaded package (expected $latest_version, got $new_version)."
fi

if [[ -f "$BASELINE_FILE" ]]; then
  cp -f "$BASELINE_FILE" "$backup_dir/baseline-current"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  cp -f "$CONFIG_FILE" "$backup_dir/config"
fi

[[ -x "$source_dir/installer/install.sh" ]] || fail "Update package installer is missing or not executable."

info "Running installer from update package..."
BASE_DIR="$BASE_DIR" MSM_INSTALL_NONINTERACTIVE=1 MSM_PRESERVE_BASELINE=1 "$source_dir/installer/install.sh"

if [[ -f "$backup_dir/baseline-current" ]]; then
  cp -f "$backup_dir/baseline-current" "$BASELINE_FILE"
fi

if [[ -f "$backup_dir/config" ]]; then
  cp -f "$backup_dir/config" "$CONFIG_FILE"
fi

info "Reloading LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_FILE"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true

log_event "Upgrade completed successfully to version $new_version."
echo "Upgrade completed: $new_version"
