#!/bin/zsh

# Mac Security Monitor help command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

cat <<'USAGE'
Mac Security Monitor

Usage:
  security-monitor
  security-monitor --version
  security-monitor log
  security-monitor last-change
  security-monitor update-baseline
  security-monitor check-update
  security-monitor upgrade
  security-monitor reinstall
  security-monitor report
  security-monitor audit
USAGE
