#!/bin/zsh

# Mac Security Monitor status command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

echo "=== Mac Security Monitor Status ==="
echo "Version: $(normalize_version "$(read_local_version)")"

echo
echo "LaunchAgent registration:"
if launchagent_loaded_for_current_install; then
  echo "Loaded: yes ($LAUNCH_AGENT_LABEL)"
elif launchagent_loaded; then
  echo "Loaded: no (a different installation with the same label appears active)"
else
  echo "Loaded: no"
fi

echo
echo "LaunchAgent file:"
if [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
  echo "Present: yes"
else
  echo "Present: no"
fi

echo
echo "Baseline file:"
if [[ -f "$BASELINE_FILE" ]]; then
  echo "Present: yes"
  echo "Last modified: $(stat -f '%Sm' "$BASELINE_FILE")"
else
  echo "Present: no"
fi

echo
echo "Last detected change:"
if [[ -f "$LAST_CHANGE_FILE" ]]; then
  last_change_value="$(read_state_value_safe "$LAST_CHANGE_FILE" || true)"
  if [[ -n "$last_change_value" ]]; then
    echo "$last_change_value"
  else
    echo "State file is unreadable or empty."
  fi
else
  echo "No detected changes recorded yet."
fi

echo
echo "Pending change alert:"
if [[ -f "$PENDING_CHANGE_ALERT_FILE" ]]; then
  echo "Present: yes"
  echo "Last updated: $(stat -f '%Sm' "$PENDING_CHANGE_ALERT_FILE")"
  if [[ -f "$PENDING_CHANGE_UPDATED_AT_FILE" ]]; then
    pending_timestamp="$(read_state_value_safe "$PENDING_CHANGE_UPDATED_AT_FILE" || true)"
    if [[ -n "$pending_timestamp" ]]; then
      echo "Pending state timestamp: $pending_timestamp"
    else
      echo "Pending state timestamp: unreadable"
    fi
  fi
  if [[ -f "$PENDING_CHANGE_GUI_STATUS_FILE" ]]; then
    gui_status_value="$(read_state_value_safe "$PENDING_CHANGE_GUI_STATUS_FILE" || true)"
    gui_status_value="$(sanitize_gui_status_value "$gui_status_value")"
    echo "GUI status: $gui_status_value"
  fi
  if [[ -f "$PENDING_CHANGE_SUMMARY_FILE" ]]; then
    top_finding="$(read_state_key_value_safe "$PENDING_CHANGE_SUMMARY_FILE" 'Top finding: ' || true)"
    if [[ -n "$top_finding" ]]; then
      echo "Top pending finding: $top_finding"
    else
      echo "Top pending finding: unavailable"
    fi
  fi
  if [[ -f "$PENDING_CHANGE_GUI_ERROR_FILE" ]]; then
    gui_error_summary="$(read_state_key_value_safe "$PENDING_CHANGE_GUI_ERROR_FILE" 'Error: ' || true)"
    if [[ -n "$gui_error_summary" ]]; then
      echo "Last GUI error: $gui_error_summary"
    else
      echo "Last GUI error: unreadable"
    fi
  fi
else
  echo "Present: no"
fi

echo
echo "Scripts:"
for script in maccheck maccheck-alert security-monitor security-monitor-update reinstall.sh update-check.sh update-install.sh commands/self-test.sh; do
  if [[ -x "$BIN_DIR/$script" ]]; then
    echo "$script: executable"
  else
    echo "$script: missing or not executable"
  fi
done

echo
echo "maccheck sample output:"
if [[ -x "$BIN_DIR/maccheck" ]]; then
  sample_file="$(mktemp -t mac-security-monitor-status-sample.XXXXXX)"
  if "$BIN_DIR/maccheck" >"$sample_file" 2>/dev/null; then
    sed -n '1,5p' "$sample_file"
  else
    echo "Unavailable"
  fi
  rm -f "$sample_file"
else
  echo "Unavailable"
fi
