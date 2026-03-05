#!/bin/zsh

# Mac Security Monitor shared library
# Author: Francesco Poltero

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
BIN_DIR="$BASE_DIR/bin"
DOC_DIR="$BASE_DIR/docs"
DOC_FILE="$DOC_DIR/README.md"
VERSION_FILE="$BASE_DIR/VERSION"
CONFIG_FILE="$BASE_DIR/config"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/monitor.log"
BASELINE_DIR="$BASE_DIR/baseline"
BASELINE_FILE="$BASELINE_DIR/current"
STATE_DIR="$BASE_DIR/state"
LAST_CHANGE_FILE="$STATE_DIR/last-change"
LAST_UPDATE_CHECK_FILE="$STATE_DIR/last-update-check"

LAUNCH_AGENT_LABEL="com.frapo78.securitycheck"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"

REMOTE_VERSION_URL="${MSM_REMOTE_VERSION_URL:-https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/VERSION}"
REPO_ARCHIVE_URL="${MSM_REPO_ARCHIVE_URL:-https://codeload.github.com/Frapo78/mac-security-monitor/tar.gz/refs/heads/main}"
CURL_MAX_TIME="${MSM_CURL_MAX_TIME:-30}"
MSM_LOGGING="${MSM_LOGGING:-1}"

print_info() { echo "[INFO] $*"; }
print_ok() { echo "[OK]   $*"; }
print_warn() { echo "[WARN] $*"; }
print_error() { echo "[ERROR] $*"; }

safe_mkdir() {
  mkdir -p "$1"
}

log_event() {
  local message="$1"

  if [[ "$MSM_LOGGING" == "0" ]]; then
    return 0
  fi

  safe_mkdir "$LOG_DIR" 2>/dev/null || return 0
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$LOG_FILE" 2>/dev/null || true
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    print_error "Required command not found: $1"
    return 1
  }
}

check_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

read_local_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    head -n 1 "$VERSION_FILE" | tr -d '[:space:]'
  else
    echo "0.0.0"
  fi
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

launchagent_loaded() {
  if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
    return 0
  fi

  launchctl list | grep -q "$LAUNCH_AGENT_LABEL"
}

auto_update_check_enabled() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return 1
  fi

  local value
  value="$(grep -E '^AUTO_UPDATE_CHECK=' "$CONFIG_FILE" | tail -n 1 | cut -d '=' -f 2 | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$value" == "true" ]]
}

should_run_daily_update_check() {
  safe_mkdir "$STATE_DIR" 2>/dev/null || return 1

  if [[ ! -f "$LAST_UPDATE_CHECK_FILE" ]]; then
    return 0
  fi

  local now_ts last_ts
  now_ts="$(date +%s)"
  last_ts="$(stat -f '%m' "$LAST_UPDATE_CHECK_FILE" 2>/dev/null || echo 0)"

  (( now_ts - last_ts >= 86400 ))
}
