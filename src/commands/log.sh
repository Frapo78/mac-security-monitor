#!/bin/zsh

# Mac Security Monitor log command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

if [[ -f "$LOG_FILE" ]]; then
  tail -n 200 "$LOG_FILE"
else
  print_error "Log file not found: $LOG_FILE"
  exit 1
fi
