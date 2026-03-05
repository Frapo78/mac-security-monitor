#!/bin/zsh

# Mac Security Monitor last-change command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

if [[ -f "$LAST_CHANGE_FILE" ]]; then
  cat "$LAST_CHANGE_FILE"
else
  echo "No detected changes recorded yet."
fi
