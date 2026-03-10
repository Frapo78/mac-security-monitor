#!/bin/zsh

# Mac Security Monitor report command
# Author: Francesco Poltero

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=src/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

SUMMARY_ONLY=0
FULL_OUTPUT=0
GUI_OUTPUT=0

usage() {
  cat <<'USAGE'
Usage:
  security-monitor report
  security-monitor report --summary
  security-monitor report --full
  security-monitor report --gui
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary)
      SUMMARY_ONLY=1
      ;;
    --full)
      FULL_OUTPUT=1
      ;;
    --gui)
      GUI_OUTPUT=1
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

if (( SUMMARY_ONLY == 1 && FULL_OUTPUT == 1 )); then
  print_error "Use either --summary or --full, not both."
  exit 1
fi

[[ -x "$BIN_DIR/maccheck" ]] || {
  print_error "maccheck not found or not executable: $BIN_DIR/maccheck"
  exit 1
}

[[ -f "$BASELINE_FILE" ]] || {
  print_error "Baseline file not found: $BASELINE_FILE"
  exit 1
}

safe_mkdir "$STATE_DIR"

tmp_root="$(mktemp -d -t mac-security-monitor-report.XXXXXX)"
current_snapshot="$tmp_root/current-snapshot.txt"
baseline_dir="$tmp_root/baseline"
current_dir="$tmp_root/current"
summary_file="$tmp_root/summary.txt"
details_file="$tmp_root/details.txt"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

normalize_section_key() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g; s/__\+/_/g; s/^_//; s/_$//'
}

category_for_section() {
  case "$1" in
    "Non-Apple Launchctl Labels (user domain)"|"LaunchAgents in User Library"|"LaunchAgents in System Library"|"LaunchDaemons in System Library"|"LaunchAgent/LaunchDaemon Forensic Metadata")
      echo "startup persistence"
      ;;
    "Applications in /Applications")
      echo "applications"
      ;;
    "Listening TCP Summary"|"Established TCP Connections (Deep Mode)"|"Network Configuration Summary (Deep Mode)")
      echo "network exposure"
      ;;
    "Non-Apple Kernel Extensions")
      echo "kernel and extensions"
      ;;
    "Setuid Binaries"|"User Login Items"|"Cron and Periodic Tasks")
      echo "scheduled tasks and execution surfaces"
      ;;
    "macOS Security Controls")
      echo "security controls"
      ;;
    "Configuration Profiles")
      echo "configuration profiles"
      ;;
    *)
      echo "other"
      ;;
  esac
}

severity_for_section() {
  case "$1" in
    "LaunchAgent/LaunchDaemon Forensic Metadata"|"Listening TCP Summary"|"Established TCP Connections (Deep Mode)"|"macOS Security Controls")
      echo "high"
      ;;
    "Non-Apple Launchctl Labels (user domain)"|"LaunchAgents in User Library"|"LaunchAgents in System Library"|"LaunchDaemons in System Library"|"User Login Items"|"Cron and Periodic Tasks"|"Configuration Profiles"|"Non-Apple Kernel Extensions")
      echo "medium"
      ;;
    *)
      echo "low"
      ;;
  esac
}

split_snapshot() {
  local source_file="$1"
  local out_dir="$2"
  local index_file="$3"
  local current_title=""
  local current_key=""
  local line=""

  mkdir -p "$out_dir"
  : >"$index_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "=== "* && "$line" == *" ===" ]]; then
      current_title="${line#=== }"
      current_title="${current_title% ===}"
      current_key="$(normalize_section_key "$current_title")"
      printf '%s\t%s\n' "$current_key" "$current_title" >>"$index_file"
      : >"$out_dir/$current_key"
      continue
    fi

    if [[ -n "$current_key" ]]; then
      printf '%s\n' "$line" >>"$out_dir/$current_key"
    fi
  done <"$source_file"
}

count_diff_lines() {
  local prefix="$1"
  local diff_file="$2"
  awk -v prefix="$prefix" 'index($0, prefix) == 1 {count++} END {print count+0}' "$diff_file" 2>/dev/null | tr -d ' '
}

print_diff_block() {
  local prefix="$1"
  local header_prefix="$2"
  local diff_file="$3"
  local lines=""

  lines="$(awk -v prefix="$prefix" -v header_prefix="$header_prefix" '
    index($0, prefix) == 1 && index($0, header_prefix) != 1 {print substr($0, 2)}
  ' "$diff_file")"

  if [[ -n "$lines" ]]; then
    printf '%s\n' "$lines"
  else
    echo "(none)"
  fi
}

"$BIN_DIR/maccheck" >"$current_snapshot"

baseline_index="$tmp_root/baseline-index.tsv"
current_index="$tmp_root/current-index.tsv"
split_snapshot "$BASELINE_FILE" "$baseline_dir" "$baseline_index"
split_snapshot "$current_snapshot" "$current_dir" "$current_index"

typeset -A baseline_titles current_titles

while IFS=$'\t' read -r key title; do
  [[ -n "$key" ]] || continue
  baseline_titles[$key]="$title"
done <"$baseline_index"

while IFS=$'\t' read -r key title; do
  [[ -n "$key" ]] || continue
  current_titles[$key]="$title"
done <"$current_index"

typeset -a section_keys
section_keys=()

while IFS=$'\t' read -r key _; do
  [[ -n "$key" ]] || continue
  section_keys+=("$key")
done <"$baseline_index"

while IFS=$'\t' read -r key _; do
  [[ -n "$key" ]] || continue
  section_keys+=("$key")
done <"$current_index"

section_keys=("${(@ou)section_keys}")

typeset -a high_entries medium_entries low_entries
high_entries=()
medium_entries=()
low_entries=()

typeset -A category_seen
typeset -A severity_counts
category_seen=()
severity_counts=()

for level in high medium low; do
  severity_counts[$level]=0
done

for key in "${section_keys[@]}"; do
  title="${current_titles[$key]:-${baseline_titles[$key]:-$key}}"
  baseline_section="$baseline_dir/$key"
  current_section="$current_dir/$key"
  [[ -f "$baseline_section" ]] || : >"$baseline_section"
  [[ -f "$current_section" ]] || : >"$current_section"

  if cmp -s "$baseline_section" "$current_section"; then
    continue
  fi

  diff_file="$tmp_root/$key.diff"
  diff -u "$baseline_section" "$current_section" >"$diff_file" || true

  add_count="$(count_diff_lines '+' "$diff_file")"
  remove_count="$(count_diff_lines '-' "$diff_file")"
  if (( add_count >= 1 )); then
    add_count=$((add_count - 1))
  fi
  if (( remove_count >= 1 )); then
    remove_count=$((remove_count - 1))
  fi

  category="$(category_for_section "$title")"
  severity="$(severity_for_section "$title")"
  category_seen[$category]=1
  severity_counts[$severity]=$(( ${severity_counts[$severity]:-0} + 1 ))

  summary_line="- [$severity] $title ($category): ${add_count} added, ${remove_count} removed"
  case "$severity" in
    high) high_entries+=("$summary_line") ;;
    medium) medium_entries+=("$summary_line") ;;
    *) low_entries+=("$summary_line") ;;
  esac

  {
    echo "=== $title ==="
    echo "Severity: $severity"
    echo "Category: $category"
    echo "Changes: ${add_count} added, ${remove_count} removed"
    echo
    echo "Added lines:"
    print_diff_block "+" "+++" "$diff_file"
    echo
    echo "Removed lines:"
    print_diff_block "-" "---" "$diff_file"
    echo
  } >>"$details_file"
done

category_count="${#category_seen[@]}"
changed_sections_count=$(( ${severity_counts[high]:-0} + ${severity_counts[medium]:-0} + ${severity_counts[low]:-0} ))

{
  echo "Mac Security Monitor Report"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Version: $(normalize_version "$(read_local_version)")"
  echo

  if (( changed_sections_count == 0 )); then
    echo "Overall status: no baseline changes detected."
    echo
    echo "The current snapshot matches the trusted baseline."
  else
    echo "Overall status: changes detected."
    echo "Changed sections: $changed_sections_count"
    echo "Changed categories: $category_count"
    echo "High severity: ${severity_counts[high]:-0}"
    echo "Medium severity: ${severity_counts[medium]:-0}"
    echo "Low severity: ${severity_counts[low]:-0}"
    echo

    if (( ${severity_counts[high]:-0} > 0 )); then
      echo "High severity findings"
      printf '%s\n' "${high_entries[@]}"
      echo
      echo "Recommended action: review high severity items before updating the baseline."
      echo
    fi

    if (( ${severity_counts[medium]:-0} > 0 )); then
      echo "Medium severity findings"
      printf '%s\n' "${medium_entries[@]}"
      echo
    fi

    if (( ${severity_counts[low]:-0} > 0 )); then
      echo "Low severity findings"
      printf '%s\n' "${low_entries[@]}"
      echo
    fi
  fi
} >"$summary_file"

{
  cat "$summary_file"
  if (( changed_sections_count > 0 )); then
    echo "Full change details"
    echo
    cat "$details_file"
    echo "Note: severity is heuristic and not proof of compromise."
  fi
} >"$LATEST_REPORT_FILE"

if (( GUI_OUTPUT == 1 )); then
  if command -v open >/dev/null 2>&1; then
    open -a TextEdit "$LATEST_REPORT_FILE" >/dev/null 2>&1 || {
      print_warn "Unable to open report in TextEdit."
    }
  else
    print_warn "The open command is not available on this system."
  fi
fi

if (( FULL_OUTPUT == 1 )); then
  cat "$LATEST_REPORT_FILE"
elif (( SUMMARY_ONLY == 1 )); then
  cat "$summary_file"
else
  cat "$summary_file"
fi

if (( changed_sections_count > 0 )); then
  exit 10
fi

exit 0
