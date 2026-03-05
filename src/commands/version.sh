#!/bin/zsh

# Mac Security Monitor version command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

echo "Mac Security Monitor $(normalize_version "$(read_local_version)")"
