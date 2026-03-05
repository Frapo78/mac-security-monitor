#!/bin/zsh

# Mac Security Monitor baseline update command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

if [[ ! -x "$BIN_DIR/maccheck" ]]; then
  print_error "maccheck not found or not executable: $BIN_DIR/maccheck"
  exit 1
fi

safe_mkdir "$BASELINE_DIR"
"$BIN_DIR/maccheck" >"$BASELINE_FILE"
log_event "Baseline updated using security-monitor update-baseline."

exec "$SCRIPT_DIR/status.sh"
