# Mac Security Monitor

![Version](https://img.shields.io/badge/version-1.0.3-blue)
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
- Bootstrap installer for one-line setup and disaster recovery

## Security Philosophy

Mac Security Monitor is designed to be:

- lightweight
- transparent
- auditable
- script-based

It uses periodic integrity snapshots rather than intrusive system monitoring.

## Architecture Overview

```text
mac-security-monitor/
├─ install.sh                   # Bootstrap installer (curl-friendly)
├─ src/
│  ├─ security-monitor
│  ├─ lib/common.sh
│  ├─ commands/
│  ├─ maccheck
│  ├─ maccheck-alert
│  └─ compatibility entrypoints
├─ installer/
│  ├─ install.sh                # Full installer (supports disaster recovery)
│  └─ uninstall.sh
├─ launchd/com.frapo78.securitycheck.plist
├─ docs/README.md
├─ VERSION
└─ CHANGELOG.md
```

## Installation

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/install.sh | zsh
```

### From source repository

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

## Disaster Recovery Install

If your local installation is broken or partially updated, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Frapo78/mac-security-monitor/main/install.sh | zsh -s -- --disaster-recovery
```

Disaster recovery mode will:

- stop and reload LaunchAgent safely
- preserve baseline and configuration when possible
- save existing logs to a recovery directory
- clean stale runtime files and intermediate artifacts
- perform a clean reinstall of scripts

Recovery logs are saved under:

- `~/.mac-security-monitor-recovery/<timestamp>/logs/`

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

## Uninstall

```bash
./installer/uninstall.sh
```

## Author

Created by **Francesco Poltero**.
