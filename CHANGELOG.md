# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and the project follows Semantic Versioning.

## [1.0.7] - 2026-03-12

### Changed

- Reduced persistence-noise in baseline comparisons by filtering Apple launchd entries and common trusted vendor components from startup-focused sections.
- Normalized dynamic `application.*` launchctl labels before snapshot comparison so transient runtime instances do not look like new persistence.
- Tightened `security-monitor report` severity logic so only newly added non-Apple, non-whitelisted persistence entries are treated as high severity.
- Tightened LaunchAgent status validation so isolated or temporary installs do not incorrectly report another installation's loaded job as their own.
- Redesigned the pending change alert flow around a 3-button GUI dialog (`Review Now`, `Update Baseline`, `Later`) with generated pending summary and detail files.
- Pending alert state now stores a fingerprint, GUI status, human-readable summary, and updated timestamp so the alert content can be refreshed without duplicating dialogs.

### Validation

- Persistence-focused normalization was applied both at snapshot time and during report comparison, so older noisy baselines do not produce large false-positive removal reports.
- Stress tests confirmed deterministic snapshot hashes across repeated runs and corrected LaunchAgent status reporting for custom `BASE_DIR` installs.

### Fixed

- Filtered the `launchctl` table header so `Label` is not captured as a fake persistence entry.
- Fixed false-green LaunchAgent checks in `security-monitor` and `security-monitor self-test` when a different installation with the same label is already loaded on the system.
- Fixed the change-alert GUI so it no longer requests 4 AppleScript buttons.
- Fixed pending alert summary/detail rendering so generated files no longer contain literal `$'\\n'` artifacts.
- Added compatibility normalization for legacy baselines that still contain the old `Label` launchctl noise entry.
- Tightened `latest-report.txt` permissions and added an optional stable report mode via `MSM_REPORT_INCLUDE_TIMESTAMP=0` for deterministic testing.
- Improved forensic metadata report clarity so `security-monitor report` identifies affected launchd plist files, labels, executables, signatures, and hash changes more clearly.

## [1.0.6] - 2026-03-10

Alert-state refinement and report-output polish release for **Mac Security Monitor**.

### Changed

- Acknowledging an alert with `Help` or `Show Details` now clears the pending alert state, so the monitor does not stay stuck in a false pending condition after a real user action.
- Release metadata was updated to `1.0.6` so OTA update detection can pick up these fixes.

### Fixed

- Fixed pending alert persistence after non-baseline-changing user actions.
- Fixed full report rendering so one-sided diffs explicitly show `(none)` for empty added or removed blocks.

### Validation

- Local smoke tests confirmed:
  - pending alert state is cleared after `Show Details`
  - full report output renders explicit `(none)` for empty diff sides

### Author

Francesco Poltero

## [1.0.5] - 2026-03-10

Alert reliability and reporting release for **Mac Security Monitor**.

### Added

- New `security-monitor report` command with:
  - grouped section-based baseline comparison
  - severity levels (`high`, `medium`, `low`)
  - `--summary`, `--full`, and `--gui` output modes
  - persisted report output under `~/.mac-security-monitor/state/latest-report.txt`

### Changed

- Alert delivery is now stateful:
  - repeated unchanged detections remain pending instead of spawning duplicated alert attempts
  - GUI delivery failures are logged explicitly instead of being treated as user dismissals
- `security-monitor` status now shows whether a pending change alert exists.
- Public CLI help now includes `security-monitor report`.
- README and docs were updated for the new command and release version.

### Fixed

- Fixed misleading `Alert dismissed without action.` behavior when AppleScript dialogs could not be displayed from the LaunchAgent context.
- Prevented repeated alert churn for the same unchanged pending detection set.

### Validation

- Local isolated smoke tests completed for:
  - report generation
  - pending alert state creation
  - repeated-run alert suppression for unchanged detections

### Author

Francesco Poltero

## [1.0.4] - 2026-03-05

Forensic snapshot hardening release for **Mac Security Monitor**.

### Added

- Deeper forensic checks in `maccheck`:
  - launchd plist metadata and SHA256
  - executable signature status for startup entries
  - login items and scheduled task visibility
  - security control posture summary (SIP, Gatekeeper, FileVault, firewall)
- Optional deep network mode for one-off investigations:
  - `MSM_DEEP_NETWORK=1 ~/.mac-security-monitor/bin/maccheck`
- First-run critical security check flow after clean install with user choice:
  - keep baseline anyway
  - keep critical alerts active
  - review detailed report
- New `security-monitor self-test` command for local smoke validation.
- New `security-monitor report` command for grouped baseline-difference reporting.
- GitHub compatibility issue template for community validation reports.

### Changed

- Improved baseline snapshot determinism to reduce false positives.
- Normalized launchd snapshot to labels only (avoids PID/status churn).
- Filtered transient Apple app service labels that could appear intermittently and trigger false positives.
- Replaced volatile default network output with stable listening summary.
- Sorted key list-based sections for consistent baseline diffs.
- Hardened command pipelines to avoid `set -euo pipefail` false failures (`exit 141`) in status and update flows.
- Updated contribution and roadmap documentation for the 1.0.4 architecture and validation process.
- Added macOS CI validation jobs for `macos-13` and `macos-14`.
- Updated README with controlled-release compatibility guidance and feedback window.
- Hardened Homebrew support with a fixed archive checksum and non-interactive installer mode that skips immediate LaunchAgent activation.
- Switched installer source-tree deployment to a staged activation flow with rollback protection.
- Removed unimplemented placeholder commands from public CLI help output.
- Added explicit Homebrew post-install guidance to README and formula caveats.

### Validation

- Local stability stress test completed with 12 consecutive snapshots and zero diff.
- Syntax and formula validation completed for the Homebrew hardening changes.

### Author

Francesco Poltero

## [1.0.3] - 2026-03-05

Stability and recovery release for **Mac Security Monitor**.

### Added

- New bootstrap installer at repository root: `install.sh`.
- One-line installation support using `curl | zsh`.
- Disaster recovery mode for installer: `installer/install.sh --disaster-recovery`.
- Recovery backup path for previous logs: `~/.mac-security-monitor-recovery/<timestamp>/logs/`.

### Changed

- Hardened installer workflow for partial or broken installations.
- Added cleanup of stale runtime/intermediate files during disaster recovery.
- Improved install workflow messaging and recovery logging.
- Updated README with one-line install and disaster recovery instructions.
- Updated Homebrew formula example to v1.0.3 archive URL.
- Expanded `maccheck` with deeper forensic checks for persistence, signatures, scheduled tasks, network state, and security control posture.

### Author

Francesco Poltero

## [1.0.2] - 2026-03-05

Architecture refactor release for **Mac Security Monitor**.

### Added

- Shared core library: `src/lib/common.sh`.
- New modular CLI dispatcher: `src/security-monitor`.
- New command modules in `src/commands/`.
- Placeholder command modules: `commands/report.sh` and `commands/audit.sh`.

### Changed

- Removed duplicated path and utility logic by centralizing shared functions in `common.sh`.
- Refactored existing command logic into modular scripts.
- Updated installer to copy the complete `src/*` tree into `~/.mac-security-monitor/bin`.
- Updated README with internal architecture documentation.
- Improved CI checks to validate the modular script layout.
- Added ShellCheck source annotations for shared library imports across modules.

### Compatibility

- Existing CLI behavior is preserved.
- Compatibility entrypoints remain available:
  - `securitycheck-status`
  - `security-monitor-update`
  - `update-check.sh`
  - `update-install.sh`
  - `reinstall.sh`

### Fixed

- Fixed CI `Run shellcheck` failures caused by dynamic `source` path detection (SC1091).
- Documented shared-library exported path variables to avoid false positive SC2034 warnings.
- Fixed CLI execution through Homebrew symlinks by resolving the real script path in `security-monitor`.
- Hardened compatibility entrypoints to call `$BASE_DIR/bin/security-monitor` directly.
- Added post-upgrade runtime verification to detect broken installs immediately.

### Author

Francesco Poltero

## [1.0.1] - 2026-03-05

Maintenance release for the first public stable cycle of **Mac Security Monitor**.

### Added

- New `security-monitor reinstall` command.
- New `src/reinstall.sh` for safe reinstall from GitHub.
- Homebrew formula example file: `mac-security-monitor.rb`.

### Changed

- Improved CLI help output and command routing.
- Improved installer compatibility with Homebrew prefixes.
- Improved update version comparison logic to support multi-part versions.
- Updated README with Updating, Reinstall, Homebrew, and Future Roadmap sections.
- Updated CI validation to include `reinstall.sh`.

### Fixed

- LaunchAgent status detection uses label `com.frapo78.securitycheck` consistently.

### Author

Francesco Poltero

## [1.0.0] - 2026-03-05

First public release candidate of **Mac Security Monitor**.

### Added

- `VERSION` file with `1.0.0`.
- New `src/security-monitor-update` script for baseline update workflow.
- New OTA scripts: `src/update-check.sh` and `src/update-install.sh`.
- Optional logging under `~/.mac-security-monitor/logs/monitor.log`.
- GitHub CI workflow at `.github/workflows/ci.yml`.
- README badges and screenshot placeholder asset.
- MIT `LICENSE`, `.gitignore`, `CONTRIBUTING.md`, root `README.md`.

### Changed

- Hardened shell scripts for safer quoting, predictable exit behavior, and defensive checks.
- Improved installer with command validation, plist validation, reinstall-safe behavior, and better verification.
- Improved uninstaller safety to remove only recognized project artifacts.
- Hardened LaunchAgent template with explicit `zsh` invocation, controlled environment variables, and dedicated log files.
- Added `--version` support to status command (`security-monitor --version`).
- Added update subcommands to `security-monitor`: `check-update`, `upgrade`, and `update-baseline`.
- Added optional daily update check notifications controlled by `~/.mac-security-monitor/config`.

### Author

Francesco Poltero
