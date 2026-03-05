# Mac Security Monitor

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%20Ventura%20%7C%20Sonoma-black)
![License](https://img.shields.io/badge/license-MIT-green)
![CI](https://img.shields.io/github/actions/workflow/status/Frapo78/mac-security-monitor/ci.yml?label=CI)

A lightweight integrity monitor for macOS that detects unexpected system changes using a baseline comparison approach.

Created by **Francesco Poltero**.

## Features

- Baseline-based integrity monitoring
- Hourly background monitoring through `launchd`
- Interactive GUI alerts for detected changes
- Lightweight local logging
- CLI status and baseline update commands
- Optional OTA update check and user-confirmed upgrade flow
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
│  ├─ security-monitor-update   # Baseline update command
│  ├─ update-check.sh           # Remote version check script
│  └─ update-install.sh         # OTA upgrade installer script
├─ installer/
│  ├─ install.sh                # Installer (idempotent and safe)
│  └─ uninstall.sh              # Uninstaller (artifact-scoped)
├─ launchd/
│  └─ com.frapo78.securitycheck.plist
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
- `zsh`, `launchctl`, `osascript`, `curl`, `tar`
- write access to `/usr/local/bin` (or `sudo`)

Install:

```bash
cd /path/to/mac-security-monitor
./installer/install.sh
```

Optional GUI installer:

- `/absolute/path/to/mac-security-monitor/gui/installer.applescript`

During installation, you can enable optional automatic update checks (daily check only, no automatic upgrade).

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

Update baseline through the main command:

```bash
security-monitor update-baseline
```

Direct baseline update command:

```bash
security-monitor-update
```

Check for updates:

```bash
security-monitor check-update
```

Run OTA upgrade (user confirmation required):

```bash
security-monitor upgrade
```

## How Monitoring Works

1. `maccheck` generates a current integrity snapshot.
2. `launchd` runs `maccheck-alert` at load and every hour.
3. `maccheck-alert` compares the current snapshot with baseline.
4. If differences are detected, the tool records the event and shows an action dialog.

## Baseline Concept

The baseline is the trusted reference snapshot saved in:

- `~/.mac-security-monitor/baseline/current`

When legitimate system changes occur (for example software updates), refresh the baseline with:

- `security-monitor update-baseline`
- or `security-monitor-update`

## Updates

Mac Security Monitor supports an optional OTA update workflow.

Manual update check:

```bash
security-monitor check-update
```

Manual OTA upgrade:

```bash
security-monitor upgrade
```

Upgrade process:

1. Check current and remote `VERSION`
2. Ask for user confirmation
3. Download update package from the official GitHub repository
4. Run installer from downloaded package
5. Preserve baseline and configuration
6. Reload LaunchAgent safely

Automatic update checks can be enabled in:

- `~/.mac-security-monitor/config`

Configuration key:

- `AUTO_UPDATE_CHECK=true`

When enabled, the monitor performs a daily update check and notifies the user if a new version is available.
No automatic background upgrade is performed.

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

## Security Considerations

- OTA update checks and downloads use only the official repository:
  - `https://github.com/Frapo78/mac-security-monitor`
  - `https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/VERSION`
- Users can inspect all scripts and update logic before running upgrades.
- No automatic self-upgrade runs in the background.
- Upgrade always requires explicit user confirmation.

## Troubleshooting

Command not found:

```bash
echo "$PATH"
ls -l /usr/local/bin/security-monitor
```

LaunchAgent not loaded:

```bash
launchctl list | grep com.frapo78.securitycheck
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.frapo78.securitycheck.plist
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
