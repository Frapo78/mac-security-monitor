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
REPORT_INCLUDE_TIMESTAMP="${MSM_REPORT_INCLUDE_TIMESTAMP:-1}"

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

is_persistence_section() {
  case "$1" in
    "Non-Apple Launchctl Labels (user domain)"|"LaunchAgents in User Library"|"LaunchAgents in System Library"|"LaunchDaemons in System Library"|"LaunchAgent/LaunchDaemon Forensic Metadata")
      return 0
      ;;
  esac

  return 1
}

flush_filtered_forensic_record() {
  local output_file="$1"
  local file_path="$2"
  local label="$3"
  local exec_path="$4"
  shift 4

  local normalized_label="$label"
  if [[ -n "$normalized_label" && "$normalized_label" != "unavailable" ]]; then
    normalized_label="$(normalize_launchctl_label "$normalized_label")"
  fi

  if is_known_safe_persistence_entry "$file_path" \
    || is_known_safe_persistence_entry "${normalized_label:-$label}" \
    || is_known_safe_persistence_entry "$exec_path"; then
    return
  fi

  local line=""
  for line in "$@"; do
    if [[ "$line" == "  Label: "* && -n "$normalized_label" ]]; then
      printf '  Label: %s\n' "$normalized_label" >>"$output_file"
    else
      printf '%s\n' "$line" >>"$output_file"
    fi
  done
}

normalize_persistence_section() {
  local title="$1"
  local input_file="$2"
  local output_file="$3"

  : >"$output_file"

  if [[ "$title" == "LaunchAgent/LaunchDaemon Forensic Metadata" ]]; then
    local line=""
    local current_file=""
    local current_label=""
    local current_exec=""
    typeset -a record_lines
    record_lines=()

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "File: "* ]]; then
        if (( ${#record_lines[@]} > 0 )); then
          flush_filtered_forensic_record "$output_file" "$current_file" "$current_label" "$current_exec" "${record_lines[@]}"
        fi
        record_lines=("$line")
        current_file="${line#File: }"
        current_label=""
        current_exec=""
        continue
      fi

      (( ${#record_lines[@]} > 0 )) || continue
      record_lines+=("$line")

      case "$line" in
        "  Label: "*) current_label="${line#  Label: }" ;;
        "  Executable: "*) current_exec="${line#  Executable: }" ;;
      esac
    done <"$input_file"

    if (( ${#record_lines[@]} > 0 )); then
      flush_filtered_forensic_record "$output_file" "$current_file" "$current_label" "$current_exec" "${record_lines[@]}"
    fi

    awk 'NF > 0 {print}' "$output_file" >"$output_file.cleaned"
    mv "$output_file.cleaned" "$output_file"

    return
  fi

  local normalized_line=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue

    if [[ "$line" == Directory\ not\ found:* || "$line" == *command\ not\ available.* ]]; then
      printf '%s\n' "$line" >>"$output_file"
      continue
    fi

    normalized_line="$line"
    if [[ "$title" == "Non-Apple Launchctl Labels (user domain)" ]]; then
      normalized_line="$(normalize_launchctl_label "$line")"
    fi

    [[ -n "$normalized_line" ]] || continue
    is_known_safe_persistence_entry "$normalized_line" && continue
    printf '%s\n' "$normalized_line" >>"$output_file"
  done <"$input_file"

  LC_ALL=C sort -u "$output_file" -o "$output_file"
}

prepare_comparable_section() {
  local title="$1"
  local input_file="$2"
  local output_file="$3"

  if is_persistence_section "$title"; then
    normalize_persistence_section "$title" "$input_file" "$output_file"
  else
    cp "$input_file" "$output_file"
  fi
}

severity_for_change() {
  local title="$1"
  local add_count="$2"

  if is_persistence_section "$title"; then
    if (( add_count > 0 )); then
      echo "high"
    else
      echo "medium"
    fi
    return
  fi

  severity_for_section "$title"
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

parse_forensic_records() {
  local input_file="$1"
  local output_file="$2"

  awk '
    function emit_record() {
      if (file_path != "") {
        print file_path "\t" sha256 "\t" label "\t" executable "\t" signature
      }
      file_path = ""
      sha256 = ""
      label = ""
      executable = ""
      signature = ""
    }
    /^File: / {
      emit_record()
      file_path = substr($0, 7)
      next
    }
    /^  SHA256: / { sha256 = substr($0, 11); next }
    /^  Label: / { label = substr($0, 10); next }
    /^  Executable: / { executable = substr($0, 15); next }
    /^  Signature: / { signature = substr($0, 14); next }
    END { emit_record() }
  ' "$input_file" >"$output_file"
}

build_forensic_metadata_detail() {
  local baseline_section="$1"
  local current_section="$2"
  local detail_output_file="$3"
  local summary_output_file="$4"

  local baseline_records="$tmp_root/forensic-baseline.tsv"
  local current_records="$tmp_root/forensic-current.tsv"
  local record_keys_file="$tmp_root/forensic-record-keys.txt"

  parse_forensic_records "$baseline_section" "$baseline_records"
  parse_forensic_records "$current_section" "$current_records"

  {
    awk -F $'\t' '{print $1}' "$baseline_records"
    awk -F $'\t' '{print $1}' "$current_records"
  } | grep -v '^$' | LC_ALL=C sort -u >"$record_keys_file"

  typeset -A baseline_sha baseline_label baseline_exec baseline_sig
  typeset -A current_sha current_label current_exec current_sig
  typeset -a changed_items
  local file_path=""
  local sha256=""
  local label=""
  local executable=""
  local signature=""
  local added_count=0
  local removed_count=0
  local modified_count=0
  typeset -a field_changes
  local item_state=""
  local why_it_matters=""
  local summary_line=""
  local headline=""

  while IFS=$'\t' read -r file_path sha256 label executable signature; do
    [[ -n "$file_path" ]] || continue
    baseline_sha[$file_path]="$sha256"
    baseline_label[$file_path]="$label"
    baseline_exec[$file_path]="$executable"
    baseline_sig[$file_path]="$signature"
  done <"$baseline_records"

  while IFS=$'\t' read -r file_path sha256 label executable signature; do
    [[ -n "$file_path" ]] || continue
    current_sha[$file_path]="$sha256"
    current_label[$file_path]="$label"
    current_exec[$file_path]="$executable"
    current_sig[$file_path]="$signature"
  done <"$current_records"

  why_it_matters="Background persistence changes can indicate new software, updates, or unauthorized startup behavior."

  while IFS= read -r file_path; do
    [[ -n "$file_path" ]] || continue

    if [[ -z "${baseline_sha[$file_path]:-}" && -z "${baseline_label[$file_path]:-}" && -z "${baseline_exec[$file_path]:-}" && -z "${baseline_sig[$file_path]:-}" ]]; then
      added_count=$((added_count + 1))
      changed_items+=("File: $file_path
State: added
Label: ${current_label[$file_path]:-unavailable}
Executable: ${current_exec[$file_path]:-unavailable}
Signature: ${current_sig[$file_path]:-unavailable}
SHA256: ${current_sha[$file_path]:-unavailable}")
      continue
    fi

    if [[ -z "${current_sha[$file_path]:-}" && -z "${current_label[$file_path]:-}" && -z "${current_exec[$file_path]:-}" && -z "${current_sig[$file_path]:-}" ]]; then
      removed_count=$((removed_count + 1))
      changed_items+=("File: $file_path
State: removed
Label: ${baseline_label[$file_path]:-unavailable}
Executable: ${baseline_exec[$file_path]:-unavailable}
Signature: ${baseline_sig[$file_path]:-unavailable}
SHA256: ${baseline_sha[$file_path]:-unavailable}")
      continue
    fi

    field_changes=()
    [[ "${baseline_sha[$file_path]:-}" != "${current_sha[$file_path]:-}" ]] && field_changes+=("SHA256")
    [[ "${baseline_label[$file_path]:-}" != "${current_label[$file_path]:-}" ]] && field_changes+=("Label")
    [[ "${baseline_exec[$file_path]:-}" != "${current_exec[$file_path]:-}" ]] && field_changes+=("Executable")
    [[ "${baseline_sig[$file_path]:-}" != "${current_sig[$file_path]:-}" ]] && field_changes+=("Signature")

    if (( ${#field_changes[@]} == 0 )); then
      continue
    fi

    modified_count=$((modified_count + 1))
    changed_items+=("File: $file_path
State: modified
Changed fields: ${(j:, :)field_changes}
Label: ${current_label[$file_path]:-${baseline_label[$file_path]:-unavailable}}
Executable: ${current_exec[$file_path]:-${baseline_exec[$file_path]:-unavailable}}
Old SHA256: ${baseline_sha[$file_path]:-unavailable}
New SHA256: ${current_sha[$file_path]:-unavailable}
Old Signature: ${baseline_sig[$file_path]:-unavailable}
New Signature: ${current_sig[$file_path]:-unavailable}")
  done <"$record_keys_file"

  if (( added_count > 0 )); then
    headline="A background service definition was added."
  elif (( modified_count > 0 )); then
    headline="A background service definition changed."
  else
    headline="A background service definition was removed."
  fi

  summary_line="- [high] LaunchAgent/LaunchDaemon Forensic Metadata (startup persistence): ${added_count} added, ${removed_count} removed, ${modified_count} modified"
  printf '%s\n' "$summary_line" >"$summary_output_file"

  {
    echo "=== LaunchAgent/LaunchDaemon Forensic Metadata ==="
    echo "Severity: high"
    echo "Category: startup persistence"
    echo "What changed: $headline"
    echo "Why this matters: $why_it_matters"
    echo "Why severity is high: High because launchd persistence metadata changed in a sensitive monitored area."
    echo "Changes: ${added_count} added, ${removed_count} removed, ${modified_count} modified"
    echo
    echo "Affected items:"
    if (( ${#changed_items[@]} > 0 )); then
      local changed_item=""
      for changed_item in "${changed_items[@]}"; do
        echo "$changed_item"
        echo
      done
    else
      echo "(none)"
    fi
    echo
  } >"$detail_output_file"
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
  normalized_baseline_section="$tmp_root/$key.baseline.normalized"
  normalized_current_section="$tmp_root/$key.current.normalized"
  [[ -f "$baseline_section" ]] || : >"$baseline_section"
  [[ -f "$current_section" ]] || : >"$current_section"

  prepare_comparable_section "$title" "$baseline_section" "$normalized_baseline_section"
  prepare_comparable_section "$title" "$current_section" "$normalized_current_section"

  if cmp -s "$normalized_baseline_section" "$normalized_current_section"; then
    continue
  fi

  category="$(category_for_section "$title")"
  category_seen[$category]=1

  if [[ "$title" == "LaunchAgent/LaunchDaemon Forensic Metadata" ]]; then
    forensic_detail_file="$tmp_root/$key.forensic.details"
    forensic_summary_file="$tmp_root/$key.forensic.summary"
    build_forensic_metadata_detail "$normalized_baseline_section" "$normalized_current_section" "$forensic_detail_file" "$forensic_summary_file"
    severity="high"
    severity_counts[$severity]=$(( ${severity_counts[$severity]:-0} + 1 ))
    summary_line="$(cat "$forensic_summary_file")"
    high_entries+=("$summary_line")
    cat "$forensic_detail_file" >>"$details_file"
    continue
  fi

  diff_file="$tmp_root/$key.diff"
  diff -u "$normalized_baseline_section" "$normalized_current_section" >"$diff_file" || true

  add_count="$(count_diff_lines '+' "$diff_file")"
  remove_count="$(count_diff_lines '-' "$diff_file")"
  if (( add_count >= 1 )); then
    add_count=$((add_count - 1))
  fi
  if (( remove_count >= 1 )); then
    remove_count=$((remove_count - 1))
  fi

  severity="$(severity_for_change "$title" "$add_count")"
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
  if [[ "$REPORT_INCLUDE_TIMESTAMP" != "0" ]]; then
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  fi
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
set_private_permissions "$LATEST_REPORT_FILE"

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
