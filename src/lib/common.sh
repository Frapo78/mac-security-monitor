#!/bin/zsh

# Mac Security Monitor shared library
# Author: Francesco Poltero

# shellcheck disable=SC2034
# This library exports shared path variables consumed by scripts that source it.

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
FIRST_RUN_CHECK_FILE="$STATE_DIR/first-run-security-check"
CRITICAL_ALERT_ACTIVE_FILE="$STATE_DIR/critical-alert-active"
CRITICAL_REPORT_FILE="$STATE_DIR/critical-issues-last.txt"
PENDING_CHANGE_ALERT_FILE="$STATE_DIR/pending-change-alert"
PENDING_CHANGE_SNAPSHOT_FILE="$STATE_DIR/pending-change-snapshot"
PENDING_CHANGE_GUI_ERROR_FILE="$STATE_DIR/pending-change-gui-error"
PENDING_CHANGE_SUMMARY_FILE="$STATE_DIR/pending-change-summary.txt"
PENDING_CHANGE_DETAILS_FILE="$STATE_DIR/pending-change-details.txt"
PENDING_CHANGE_FINGERPRINT_FILE="$STATE_DIR/pending-change-fingerprint"
PENDING_CHANGE_GUI_STATUS_FILE="$STATE_DIR/pending-change-gui-status"
PENDING_CHANGE_UPDATED_AT_FILE="$STATE_DIR/pending-change-updated-at"
LATEST_REPORT_FILE="$STATE_DIR/latest-report.txt"

LAUNCH_AGENT_LABEL="${MSM_LAUNCH_AGENT_LABEL:-com.frapo78.securitycheck}"
LAUNCH_AGENT_PLIST="${MSM_LAUNCH_AGENT_PLIST:-$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist}"

REMOTE_VERSION_URL="${MSM_REMOTE_VERSION_URL:-https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/VERSION}"
REPO_ARCHIVE_URL="${MSM_REPO_ARCHIVE_URL:-https://codeload.github.com/Frapo78/mac-security-monitor/tar.gz/refs/heads/main}"
CURL_MAX_TIME="${MSM_CURL_MAX_TIME:-30}"
MSM_LOGGING="${MSM_LOGGING:-1}"

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_launchctl_label() {
  local label="$1"
  label="$(printf '%s\n' "$label" | sed -E 's/(\.[0-9]+)+$//')"
  if [[ "$label" == "Label" ]]; then
    echo ""
    return
  fi
  printf '%s\n' "$label"
}

is_apple_persistence_entry() {
  local value_lc
  value_lc="$(to_lower "$1")"

  [[ "$value_lc" == com.apple.* ]] && return 0
  [[ "$value_lc" == application.com.apple.* ]] && return 0
  [[ "$value_lc" == *"/system/library/"* ]] && return 0
  [[ "$value_lc" == *"/library/apple/"* ]] && return 0

  return 1
}

is_whitelisted_vendor_entry() {
  local value_lc
  value_lc="$(to_lower "$1")"

  case "$value_lc" in
    *google*|*chrome*|*keystone*|*drivefs*|*openai*|*chatgpt*|*anthropic*|*claude*|*homebrew*|*org.homebrew*|*homebrew.mxcl*|*adobe*|*epson*|*idrive*)
      return 0
      ;;
  esac

  return 1
}

is_known_safe_persistence_entry() {
  local value="$1"
  local normalized_value

  normalized_value="$(normalize_launchctl_label "$value")"

  is_apple_persistence_entry "$normalized_value" && return 0
  is_whitelisted_vendor_entry "$normalized_value" && return 0

  return 1
}

print_info() { echo "[INFO] $*"; }
print_ok() { echo "[OK]   $*"; }
print_warn() { echo "[WARN] $*"; }
print_error() { echo "[ERROR] $*"; }

safe_mkdir() {
  mkdir -p "$1"
}

set_private_permissions() {
  chmod 0600 "$1" 2>/dev/null || true
}

touch_private_file() {
  : >"$1"
  set_private_permissions "$1"
}

write_private_state_file() {
  local target_file="$1"
  shift

  safe_mkdir "$(dirname "$target_file")" 2>/dev/null || return 1
  printf '%s' "$*" >"$target_file"
  set_private_permissions "$target_file"
}

sanitize_single_line_text() {
  local value="$1"

  value="$(printf '%s' "$value" | LC_CTYPE=C tr -cd '[:print:]\t ')"
  value="$(printf '%s' "$value" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  printf '%s\n' "$value"
}

read_state_value_safe() {
  local source_file="$1"
  local raw_value=""

  [[ -f "$source_file" ]] || return 1
  raw_value="$(LC_CTYPE=C tr '\0' '\n' <"$source_file" 2>/dev/null | head -n 1 || true)"
  sanitize_single_line_text "$raw_value"
}

read_state_key_value_safe() {
  local source_file="$1"
  local key_prefix="$2"
  local raw_value=""

  [[ -f "$source_file" ]] || return 1
  raw_value="$(LC_CTYPE=C tr '\0' '\n' <"$source_file" 2>/dev/null | awk -v prefix="$key_prefix" 'index($0, prefix) == 1 {print substr($0, length(prefix) + 1); exit}' || true)"
  raw_value="$(sanitize_single_line_text "$raw_value")"
  [[ -n "$raw_value" ]] || return 1
  printf '%s\n' "$raw_value"
}

sanitize_gui_status_value() {
  local value="$1"

  case "$value" in
    never-shown|shown|deferred|failed|updated-while-pending)
      printf '%s\n' "$value"
      ;;
    *)
      echo "invalid-state-data"
      ;;
  esac
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

launchagent_targets_current_install() {
  [[ -f "$LAUNCH_AGENT_PLIST" ]] || return 1

  local configured_base_dir=""
  local configured_program=""

  if [[ -x /usr/libexec/PlistBuddy ]]; then
    configured_base_dir="$(/usr/libexec/PlistBuddy -c 'Print :EnvironmentVariables:BASE_DIR' "$LAUNCH_AGENT_PLIST" 2>/dev/null || true)"
    configured_program="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:1' "$LAUNCH_AGENT_PLIST" 2>/dev/null || true)"
  fi

  [[ "$configured_base_dir" == "$BASE_DIR" ]] && return 0
  [[ "$configured_program" == "$BIN_DIR/maccheck-alert" ]] && return 0

  return 1
}

launchagent_loaded_for_current_install() {
  launchagent_targets_current_install || return 1
  launchagent_loaded
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
