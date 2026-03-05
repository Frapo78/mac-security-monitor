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
if launchagent_loaded; then
  echo "Loaded: yes ($LAUNCH_AGENT_LABEL)"
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
  cat "$LAST_CHANGE_FILE"
else
  echo "No detected changes recorded yet."
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
