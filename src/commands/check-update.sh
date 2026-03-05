#!/bin/zsh

# Mac Security Monitor update check command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

QUIET_MODE=0
LATEST_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  security-monitor check-update
  security-monitor check-update --quiet
  security-monitor check-update --latest
USAGE
}

read_remote_version() {
  curl -fsSL --max-time "$CURL_MAX_TIME" "$REMOTE_VERSION_URL" | head -n 1 | tr -d '[:space:]'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      QUIET_MODE=1
      ;;
    --latest)
      LATEST_ONLY=1
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

local_version="$(normalize_version "$(read_local_version)")"
remote_version="$(normalize_version "$(read_remote_version)")"

is_valid_version "$local_version" || {
  print_error "Invalid local version format: $local_version"
  exit 1
}

is_valid_version "$remote_version" || {
  print_error "Invalid remote version format: $remote_version"
  exit 1
}

if [[ "$LATEST_ONLY" == "1" ]]; then
  echo "$remote_version"
  exit 0
fi

set +e
compare_versions "$remote_version" "$local_version"
cmp_result=$?
set -e

if [[ "$QUIET_MODE" == "1" ]]; then
  case "$cmp_result" in
    1) exit 10 ;;
    0|2) exit 0 ;;
  esac
fi

echo "Mac Security Monitor"
echo "Current version: $local_version"
echo "Latest version: $remote_version"
echo

case "$cmp_result" in
  1)
    echo "Update available."
    exit 10
    ;;
  0)
    echo "You are up to date."
    exit 0
    ;;
  2)
    echo "Local installation is newer than remote version."
    exit 0
    ;;
esac
