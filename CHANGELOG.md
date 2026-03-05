# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and the project follows Semantic Versioning.

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
