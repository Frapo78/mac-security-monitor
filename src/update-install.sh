#!/bin/zsh

# Mac Security Monitor upgrade compatibility entrypoint
# Author: Francesco Poltero

set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/.mac-security-monitor}"
exec "$BASE_DIR/bin/security-monitor" upgrade "$@"
