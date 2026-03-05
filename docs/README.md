# Mac Security Monitor

![Version](https://img.shields.io/badge/version-1.0.2-blue)
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
- Status, baseline management, and update CLI commands
- Optional OTA update checks and user-confirmed upgrades
- Safe reinstall command that preserves user data

## Security Philosophy

Mac Security Monitor is designed to be:

- lightweight
- transparent
- auditable
- script-based

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
│  ├─ security-monitor          # Main CLI dispatcher
│  ├─ lib/
│  │  └─ common.sh              # Shared paths and utility functions
│  ├─ commands/
│  │  ├─ status.sh
│  │  ├─ check-update.sh
│  │  ├─ upgrade.sh
│  │  ├─ reinstall.sh
│  │  ├─ report.sh              # Placeholder
│  │  └─ audit.sh               # Placeholder
│  ├─ maccheck
│  ├─ maccheck-alert
│  ├─ securitycheck-status      # Compatibility entrypoint
│  ├─ security-monitor-update   # Compatibility entrypoint
│  ├─ update-check.sh           # Compatibility entrypoint
│  └─ update-install.sh         # Compatibility entrypoint
├─ installer/
│  ├─ install.sh
│  └─ uninstall.sh
├─ launchd/
│  └─ com.frapo78.securitycheck.plist
├─ docs/
│  ├─ README.md
│  └─ images/
│     └─ screenshot-placeholder.svg
├─ mac-security-monitor.rb
├─ ROADMAP.md
├─ .github/workflows/ci.yml
├─ VERSION
├─ LICENSE
├─ CHANGELOG.md
├─ CONTRIBUTING.md
└─ .gitignore
```

## Architecture

The tool uses a shared core library (`src/lib/common.sh`) to keep path handling, logging, and utility logic in one place.

The main CLI (`src/security-monitor`) dispatches subcommands to small modules in `src/commands/`. This keeps each command focused and easy to audit.

The monitoring pipeline remains simple: `maccheck` captures a snapshot, `maccheck-alert` compares it with the baseline, and `launchd` schedules periodic execution.

## Installation

### From source

```bash
cd /path/to/mac-security-monitor
./installer/install.sh
```

### Homebrew (tap, recommended)

```bash
brew tap frapo78/tools
brew install mac-security-monitor
```

### Homebrew (direct formula example)

```bash
brew install ./mac-security-monitor.rb
```

## CLI Usage

```bash
security-monitor
security-monitor --version
security-monitor log
security-monitor last-change
security-monitor update-baseline
security-monitor check-update
security-monitor upgrade
security-monitor reinstall
```

## Updating

Manual update check:

```bash
security-monitor check-update
```

Manual upgrade (always asks for confirmation):

```bash
security-monitor upgrade
```

Reinstall from GitHub (preserves baseline, logs, and config):

```bash
security-monitor reinstall
```

## Roadmap

Development priorities are tracked in the public roadmap:

[ROADMAP.md](./ROADMAP.md)

## How Monitoring Works

1. `maccheck` creates a system integrity snapshot.
2. `maccheck-alert` compares it with baseline `~/.mac-security-monitor/baseline/current`.
3. If differences are detected, the tool records the event and shows a GUI dialog.
4. Monitoring runs from `launchd` with label `com.frapo78.securitycheck`.

## Logging

- Main log: `~/.mac-security-monitor/logs/monitor.log`
- LaunchAgent stdout: `~/.mac-security-monitor/logs/launchd.log`
- LaunchAgent stderr: `~/.mac-security-monitor/logs/launchd.err.log`

## Security Considerations

- Update checks and upgrades use only the official repository:
  - `https://github.com/Frapo78/mac-security-monitor`
  - `https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/VERSION`
- No background auto-upgrade is performed.
- Users can inspect scripts before running upgrades or reinstalls.

## Troubleshooting

If LaunchAgent is not loaded:

```bash
launchctl list | grep com.frapo78.securitycheck
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.frapo78.securitycheck.plist
```

If baseline is missing:

```bash
~/.mac-security-monitor/bin/maccheck > ~/.mac-security-monitor/baseline/current
```

## Uninstall

```bash
./installer/uninstall.sh
```

## Author

Created by **Francesco Poltero**.
