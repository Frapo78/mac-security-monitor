# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and the project follows Semantic Versioning.

## [1.0.0] - 2026-03-05

First public release candidate of **Mac Security Monitor**.

### Added

- `VERSION` file with `1.0.0`.
- New `src/security-monitor-update` script for baseline update workflow.
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

### Author

Francesco Poltero
