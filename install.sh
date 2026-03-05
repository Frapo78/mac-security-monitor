#!/bin/zsh

# Mac Security Monitor bootstrap installer
# Author: Francesco Poltero
#
# Supports local repository execution and one-line remote installation:
# curl -fsSL https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/install.sh | zsh

set -euo pipefail

REPO_ARCHIVE_URL="${MSM_REPO_ARCHIVE_URL:-https://codeload.github.com/Frapo78/mac-security-monitor/tar.gz/refs/heads/main}"
CURL_MAX_TIME="${MSM_CURL_MAX_TIME:-30}"

DISASTER_RECOVERY=0

usage() {
  cat <<'USAGE'
Usage:
  install.sh [--disaster-recovery]

Examples:
  curl -fsSL https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/install.sh | zsh
  curl -fsSL https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/install.sh | zsh -s -- --disaster-recovery
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disaster-recovery)
      DISASTER_RECOVERY=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

run_installer() {
  local installer_path="$1"
  if [[ "$DISASTER_RECOVERY" == "1" ]]; then
    "$installer_path" --disaster-recovery
  else
    "$installer_path"
  fi
}

# If executed from a local clone, run local installer directly.
SCRIPT_DIR=""
if SCRIPT_DIR_CANDIDATE="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"; then
  SCRIPT_DIR="$SCRIPT_DIR_CANDIDATE"
fi
if [[ -n "$SCRIPT_DIR" && -x "$SCRIPT_DIR/installer/install.sh" ]]; then
  run_installer "$SCRIPT_DIR/installer/install.sh"
  exit 0
fi

command -v curl >/dev/null 2>&1 || { echo "[ERROR] curl is required"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "[ERROR] tar is required"; exit 1; }

TMP_DIR="$(mktemp -d -t mac-security-monitor-bootstrap.XXXXXX)"
ARCHIVE_FILE="$TMP_DIR/repository.tar.gz"
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[INFO] Downloading Mac Security Monitor package..."
curl -fsSL --max-time "$CURL_MAX_TIME" "$REPO_ARCHIVE_URL" -o "$ARCHIVE_FILE"

echo "[INFO] Extracting package..."
tar -xzf "$ARCHIVE_FILE" -C "$EXTRACT_DIR"

SOURCE_DIR="$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d -print -quit)"
if [[ -z "$SOURCE_DIR" || ! -x "$SOURCE_DIR/installer/install.sh" ]]; then
  echo "[ERROR] Installer not found in downloaded package."
  exit 1
fi

run_installer "$SOURCE_DIR/installer/install.sh"
