# Project Roadmap

Mac Security Monitor is designed to remain a lightweight, transparent, and auditable macOS integrity monitoring tool.

The roadmap focuses on improving usability while preserving simplicity.

---

## v1.0 — Initial Public Release

Core features:

- baseline integrity monitoring
- launchd background monitoring
- CLI commands
- logging system
- OTA update system
- installer and uninstall scripts

---

## v1.0.1 — Distribution Improvements (Completed)

Delivered features:

- Homebrew installation support
- reinstall command
- improved CLI help
- installer robustness improvements

---

## v1.0.2 — Internal Refactor (Completed)

Delivered features:

- shared core library (`src/lib/common.sh`)
- modular command dispatcher (`src/commands/`)
- improved installer consistency and path handling
- placeholder commands for future `report` and `audit` modules

---

## v1.0.3 — Installer and Recovery Hardening (Completed)

Delivered features:

- one-line bootstrap install script
- disaster recovery reinstall mode
- safer reinstall and upgrade flow
- improved launchd handling and validation

---

## v1.0.4 — Forensic Snapshot Stability (Current)

Delivered features:

- deterministic snapshot normalization to reduce false positives
- deeper forensic sections in `maccheck`
- first-run critical security check with user decision flow
- stability-focused command and pipeline hardening
- controlled compatibility validation workflow (`security-monitor self-test` + community reports)

---

## v1.0.5 — Reporting and Triage (Planned)

Planned features:

- human-readable change reports
- `security-monitor report` command
- better log visualization and triage guidance

---

## v1.1 — User Interface (Planned)

Planned features:

- macOS menu bar application
- quick system check from UI
- log viewer
- manual baseline update from UI

---

## Long-Term Vision

Mac Security Monitor aims to become a transparent and lightweight security auditing tool for macOS that prioritizes simplicity and auditability over complexity.

Author: Francesco Poltero
