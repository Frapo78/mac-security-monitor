#!/bin/zsh

# Mac Security Monitor
# Author: Francesco Poltero
#
# Checks for newer versions from the official GitHub repository.

set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
LOCAL_VERSION_FILE="$BASE_DIR/VERSION"
REMOTE_VERSION_URL="${MSM_REMOTE_VERSION_URL:-https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/VERSION}"
CURL_MAX_TIME="${MSM_CURL_MAX_TIME:-15}"

QUIET_MODE=0
LATEST_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  update-check.sh
  update-check.sh --quiet
  update-check.sh --latest
USAGE
}

normalize_version() {
  local version="$1"
  version="${version#v}"
  echo "$version"
}

is_valid_version() {
  local version="$1"
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]
}

read_local_version() {
  if [[ -f "$LOCAL_VERSION_FILE" ]]; then
    head -n 1 "$LOCAL_VERSION_FILE" | tr -d '[:space:]'
  else
    echo "0.0.0"
  fi
}

read_remote_version() {
  curl -fsSL --max-time "$CURL_MAX_TIME" "$REMOTE_VERSION_URL" | head -n 1 | tr -d '[:space:]'
}

# Return codes:
# 0 -> equal
# 1 -> first is greater
# 2 -> second is greater
compare_versions() {
  local left="$1"
  local right="$2"

  local -a left_parts right_parts
  local i max_len l_part r_part

  IFS='.' read -rA left_parts <<<"$left"
  IFS='.' read -rA right_parts <<<"$right"

  max_len=${#left_parts[@]}
  if (( ${#right_parts[@]} > max_len )); then
    max_len=${#right_parts[@]}
  fi

  for ((i = 1; i <= max_len; i++)); do
    l_part="${left_parts[$i]:-0}"
    r_part="${right_parts[$i]:-0}"

    if ((10#$l_part > 10#$r_part)); then
      return 1
    fi
    if ((10#$l_part < 10#$r_part)); then
      return 2
    fi
  done

  return 0
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
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

local_version="$(normalize_version "$(read_local_version)")"
remote_version="$(normalize_version "$(read_remote_version)")"

is_valid_version "$local_version" || {
  echo "[ERROR] Invalid local version format: $local_version"
  exit 1
}

is_valid_version "$remote_version" || {
  echo "[ERROR] Invalid remote version format: $remote_version"
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
