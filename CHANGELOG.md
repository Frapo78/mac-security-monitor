# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and the project follows Semantic Versioning.

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
