#!/bin/zsh

# Mac Security Monitor reinstall command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

verify_installation() {
  [[ -x "$BIN_DIR/maccheck" ]] || { print_error "maccheck is missing after reinstall."; return 1; }
  [[ -x "$BIN_DIR/maccheck-alert" ]] || { print_error "maccheck-alert is missing after reinstall."; return 1; }
  [[ -x "$BIN_DIR/security-monitor" ]] || { print_error "security-monitor is missing after reinstall."; return 1; }
  [[ -f "$VERSION_FILE" ]] || { print_error "VERSION file is missing after reinstall."; return 1; }
}

require_command curl
require_command tar
require_command launchctl

echo "Mac Security Monitor"
echo "Reinstalling from GitHub..."

tmp_dir="$(mktemp -d -t mac-security-monitor-reinstall.XXXXXX)"
archive_file="$tmp_dir/repository.tar.gz"
extract_dir="$tmp_dir/extracted"
backup_dir="$tmp_dir/backup"
safe_mkdir "$extract_dir"
safe_mkdir "$backup_dir"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo
echo "Preserving configuration..."
if [[ -f "$BASELINE_FILE" ]]; then
  safe_mkdir "$backup_dir/baseline"
  cp -f "$BASELINE_FILE" "$backup_dir/baseline/current"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  cp -f "$CONFIG_FILE" "$backup_dir/config"
fi

if [[ -d "$LOG_DIR" ]]; then
  safe_mkdir "$backup_dir/logs"
  cp -R "$LOG_DIR"/. "$backup_dir/logs"/ 2>/dev/null || true
fi

echo "Downloading latest version..."
if ! curl -fsSL --max-time "$CURL_MAX_TIME" "$REPO_ARCHIVE_URL" -o "$archive_file"; then
  print_error "Failed to download repository archive from GitHub."
  exit 1
fi

echo "Running installer..."
if ! tar -xzf "$archive_file" -C "$extract_dir"; then
  print_error "Failed to extract repository archive."
  exit 1
fi

source_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$source_dir" ]] || { print_error "Invalid archive layout."; exit 1; }

[[ -x "$source_dir/installer/install.sh" ]] || { print_error "Installer not found in downloaded package."; exit 1; }

BASE_DIR="$BASE_DIR" MSM_INSTALL_NONINTERACTIVE=1 MSM_PRESERVE_BASELINE=1 "$source_dir/installer/install.sh"

if [[ -f "$backup_dir/baseline/current" ]]; then
  safe_mkdir "$BASELINE_DIR"
  cp -f "$backup_dir/baseline/current" "$BASELINE_FILE"
fi

if [[ -f "$backup_dir/config" ]]; then
  cp -f "$backup_dir/config" "$CONFIG_FILE"
fi

if [[ -d "$backup_dir/logs" ]]; then
  safe_mkdir "$LOG_DIR"
  cp -R "$backup_dir/logs"/. "$LOG_DIR"/ 2>/dev/null || true
fi

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true

verify_installation
log_event "Reinstallation completed successfully from GitHub."

echo
echo "Reinstallation complete."
