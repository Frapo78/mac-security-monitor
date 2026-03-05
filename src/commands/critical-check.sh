#!/bin/zsh

# Mac Security Monitor critical security check command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

QUIET_MODE=0

usage() {
  cat <<'USAGE'
Usage:
  security-monitor internal critical-check [--quiet]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      QUIET_MODE=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      print_error "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

safe_mkdir "$STATE_DIR"

issues=()

if command -v csrutil >/dev/null 2>&1; then
  sip_status="$(csrutil status 2>/dev/null || true)"
  if echo "$sip_status" | grep -qi "disabled"; then
    issues+=("System Integrity Protection appears disabled: $sip_status")
  fi
fi

if command -v spctl >/dev/null 2>&1; then
  gk_status="$(spctl --status 2>/dev/null || true)"
  if echo "$gk_status" | grep -qi "disabled"; then
    issues+=("Gatekeeper appears disabled: $gk_status")
  fi
fi

if [[ -x /usr/libexec/ApplicationFirewall/socketfilterfw ]]; then
  fw_status="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true)"
  if echo "$fw_status" | grep -qi "disabled"; then
    issues+=("Application Firewall appears disabled: $fw_status")
  fi
fi

if (( ${#issues[@]} > 0 )); then
  {
    echo "Mac Security Monitor Critical Security Check"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "Critical issues detected:"
    for item in "${issues[@]}"; do
      echo "- $item"
    done
  } >"$CRITICAL_REPORT_FILE"

  if [[ "$QUIET_MODE" != "1" ]]; then
    cat "$CRITICAL_REPORT_FILE"
  fi

  exit 20
fi

{
  echo "Mac Security Monitor Critical Security Check"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "No critical issues detected."
} >"$CRITICAL_REPORT_FILE"

if [[ "$QUIET_MODE" != "1" ]]; then
  cat "$CRITICAL_REPORT_FILE"
fi

exit 0
