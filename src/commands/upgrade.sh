#!/bin/zsh

# Mac Security Monitor upgrade command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ASSUME_YES=0

usage() {
  cat <<'USAGE'
Usage:
  security-monitor upgrade
  security-monitor upgrade --yes
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
      print_error "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

require_command curl
require_command tar
require_command launchctl

set +e
"$SCRIPT_DIR/check-update.sh" --quiet
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
    print_error "Could not verify remote version."
    exit 1
    ;;
esac

latest_version="$("$SCRIPT_DIR/check-update.sh" --latest)"
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
safe_mkdir "$extract_dir"
safe_mkdir "$backup_dir"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

print_info "Downloading latest repository archive..."
if ! curl -fsSL --max-time "$CURL_MAX_TIME" "$REPO_ARCHIVE_URL" -o "$archive_file"; then
  print_error "Failed to download update package from official repository."
  exit 1
fi

print_info "Extracting update package..."
if ! tar -xzf "$archive_file" -C "$extract_dir"; then
  print_error "Failed to extract update package."
  exit 1
fi

source_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -n "$source_dir" ]] || {
  print_error "Invalid update package layout."
  exit 1
}

new_version_file="$source_dir/VERSION"
[[ -f "$new_version_file" ]] || {
  print_error "Update package does not include VERSION file."
  exit 1
}

new_version="$(head -n 1 "$new_version_file" | tr -d '[:space:]')"
if [[ "$(normalize_version "$new_version")" != "$(normalize_version "$latest_version")" ]]; then
  print_error "VERSION mismatch in downloaded package."
  exit 1
fi

if [[ -f "$BASELINE_FILE" ]]; then
  cp -f "$BASELINE_FILE" "$backup_dir/baseline-current"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  cp -f "$CONFIG_FILE" "$backup_dir/config"
fi

[[ -x "$source_dir/installer/install.sh" ]] || {
  print_error "Update package installer is missing or not executable."
  exit 1
}

print_info "Running installer from update package..."
BASE_DIR="$BASE_DIR" MSM_INSTALL_NONINTERACTIVE=1 MSM_PRESERVE_BASELINE=1 "$source_dir/installer/install.sh"

if [[ -f "$backup_dir/baseline-current" ]]; then
  cp -f "$backup_dir/baseline-current" "$BASELINE_FILE"
fi

if [[ -f "$backup_dir/config" ]]; then
  cp -f "$backup_dir/config" "$CONFIG_FILE"
fi

print_info "Reloading LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST"
launchctl enable "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true

log_event "Upgrade completed successfully to version $new_version."
echo "Upgrade completed: $new_version"
