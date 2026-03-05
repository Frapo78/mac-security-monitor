#!/bin/zsh

# Mac Security Monitor self-test command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

failures=0
warnings=0

ok_msg() {
  echo "[OK]   $*"
}

warn_msg() {
  echo "[WARN] $*"
  warnings=$((warnings + 1))
}

fail_msg() {
  echo "[FAIL] $*"
  failures=$((failures + 1))
}

echo "Mac Security Monitor self-test"
echo

if check_macos; then
  ok_msg "Running on macOS."
else
  fail_msg "This command must run on macOS."
fi

if [[ -x "$BIN_DIR/security-monitor" ]]; then
  ok_msg "CLI entrypoint is executable."
else
  fail_msg "CLI entrypoint missing or not executable: $BIN_DIR/security-monitor"
fi

for script in maccheck maccheck-alert security-monitor-update commands/status.sh commands/update-baseline.sh commands/check-update.sh commands/upgrade.sh commands/reinstall.sh commands/critical-check.sh; do
  if [[ -x "$BIN_DIR/$script" ]]; then
    ok_msg "Executable found: $script"
  else
    fail_msg "Missing or non-executable script: $script"
  fi
done

safe_mkdir "$BASELINE_DIR"
safe_mkdir "$LOG_DIR"
safe_mkdir "$STATE_DIR"

if [[ -f "$VERSION_FILE" ]]; then
  version_value="$(read_local_version)"
  if is_valid_version "$(normalize_version "$version_value")"; then
    ok_msg "VERSION file is present and valid: $(normalize_version "$version_value")"
  else
    fail_msg "Invalid VERSION format in $VERSION_FILE"
  fi
else
  fail_msg "VERSION file not found: $VERSION_FILE"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  ok_msg "Configuration file is present."
else
  warn_msg "Configuration file not found (installer may not have completed)."
fi

if [[ -f "$BASELINE_FILE" ]]; then
  ok_msg "Baseline file is present."
else
  warn_msg "Baseline file is missing. Run: security-monitor update-baseline"
fi

if [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
  ok_msg "LaunchAgent plist is present."
else
  fail_msg "LaunchAgent plist not found: $LAUNCH_AGENT_PLIST"
fi

if launchagent_loaded; then
  ok_msg "LaunchAgent appears loaded."
else
  warn_msg "LaunchAgent is not currently loaded."
fi

if [[ -x "$BIN_DIR/maccheck" ]]; then
  snapshot_file="$(mktemp -t mac-security-monitor-selftest.XXXXXX)"
  if "$BIN_DIR/maccheck" >"$snapshot_file" 2>/dev/null; then
    if [[ -s "$snapshot_file" ]]; then
      ok_msg "maccheck snapshot generation succeeded."
    else
      fail_msg "maccheck returned empty snapshot output."
    fi
  else
    fail_msg "maccheck execution failed."
  fi
  rm -f "$snapshot_file"
else
  fail_msg "Cannot run maccheck because it is not executable."
fi

echo
echo "Summary: $failures failure(s), $warnings warning(s)."

if (( failures > 0 )); then
  exit 1
fi

if (( warnings > 0 )); then
  exit 2
fi

exit 0
