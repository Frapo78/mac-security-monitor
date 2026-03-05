# Mac Security Monitor

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%20Ventura%20%7C%20Sonoma-black)
![License](https://img.shields.io/badge/license-MIT-green)
![CI](https://img.shields.io/github/actions/workflow/status/francescopoltero/mac-security-monitor/ci.yml?label=CI)

A lightweight integrity monitor for macOS that detects unexpected system changes using a baseline comparison approach.

Created by **Francesco Poltero**.

## Features

- Baseline-based integrity monitoring
- Hourly background monitoring via `launchd`
- Interactive alert dialog for detected changes
- Lightweight local logging
- Status and baseline management CLI commands
- Script-based architecture with no heavy dependencies

## Security Philosophy

Mac Security Monitor is designed to be:

- simple
- transparent
- auditable
- lightweight

It uses periodic integrity snapshots rather than intrusive system monitoring.

## Problem It Solves

macOS users often have no simple way to detect unexpected system changes.

Existing tools are often:

- complex
- intrusive
- difficult to audit

Mac Security Monitor provides a transparent alternative.

## Architecture Overview

```text
mac-security-monitor/
├─ src/
│  ├─ maccheck                  # Collect current system security state
│  ├─ maccheck-alert            # Compare against baseline and alert user
│  ├─ securitycheck-status      # CLI status and utility subcommands
│  └─ security-monitor-update   # Baseline update command
├─ installer/
│  ├─ install.sh                # Installer (idempotent and safe)
│  └─ uninstall.sh              # Uninstaller (artifact-scoped)
├─ launchd/
│  └─ com.fra.securitycheck.plist
├─ gui/
│  └─ installer.applescript
├─ docs/
│  ├─ README.md
│  └─ images/
│     └─ screenshot-placeholder.svg
├─ .github/workflows/ci.yml
├─ VERSION
├─ LICENSE
├─ CHANGELOG.md
├─ CONTRIBUTING.md
└─ .gitignore
```

## Installation

Requirements:

- macOS Ventura or newer
- `zsh`, `launchctl`, `osascript`
- write access to `/usr/local/bin` (or `sudo`)

Install:

```bash
cd /path/to/mac-security-monitor
./installer/install.sh
```

Optional GUI installer:

- `/absolute/path/to/mac-security-monitor/gui/installer.applescript`

## CLI Usage

Show monitor status:

```bash
security-monitor
```

Show version:

```bash
security-monitor --version
```

Show monitor log:

```bash
security-monitor log
```

Show last detected change:

```bash
security-monitor last-change
```

Update baseline and print status:

```bash
security-monitor-update
```

## How Monitoring Works

1. `maccheck` generates a current integrity snapshot.
2. `launchd` runs `maccheck-alert` at load and every hour.
3. `maccheck-alert` compares current snapshot with baseline.
4. If changes are detected, the tool records the event and shows an action dialog.

## Baseline Concept

The baseline is the trusted reference snapshot saved in:

- `~/.mac-security-monitor/baseline/current`

When legitimate system changes occur (for example software updates), refresh the baseline with:

- `security-monitor-update`

## Logging

Main log file:

- `~/.mac-security-monitor/logs/monitor.log`

Launchd output files:

- `~/.mac-security-monitor/logs/launchd.log`
- `~/.mac-security-monitor/logs/launchd.err.log`

Disable script logging for one run:

```bash
MSM_LOGGING=0 ~/.mac-security-monitor/bin/maccheck-alert
```

## Troubleshooting

Command not found:

```bash
echo "$PATH"
ls -l /usr/local/bin/security-monitor
```

LaunchAgent not loaded:

```bash
launchctl list | grep com.fra.securitycheck
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist
```

Missing baseline:

```bash
~/.mac-security-monitor/bin/maccheck > ~/.mac-security-monitor/baseline/current
```

## Uninstall Instructions

```bash
cd /path/to/mac-security-monitor
./installer/uninstall.sh
```

## Author

Created by **Francesco Poltero**.
