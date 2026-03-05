#!/bin/zsh

# Mac Security Monitor upgrade compatibility entrypoint
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
exec "$SCRIPT_DIR/security-monitor" upgrade "$@"
