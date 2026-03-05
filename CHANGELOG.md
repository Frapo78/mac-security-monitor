# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project uses Semantic Versioning.

## [1.0.0] - 2026-03-05

Initial public release candidate for **Mac Security Monitor**.

### Added

- MIT `LICENSE`.
- `.gitignore` for macOS and project artifacts.
- `CONTRIBUTING.md` with development and contribution guidance.
- Root `README.md` for GitHub distribution.

### Changed

- Refactored all shell scripts to English-only comments and messages.
- Introduced consistent `BASE_DIR` usage across runtime and status scripts.
- Improved installer portability (works from any current directory).
- Hardened install/uninstall flows with safer checks and clearer feedback.
- Updated LaunchAgent template with placeholder-based path injection and log files.
- Improved optional AppleScript GUI installer to resolve repository-relative paths safely.
- Expanded documentation for architecture, usage, troubleshooting, and security philosophy.

### Author

Francesco Poltero
