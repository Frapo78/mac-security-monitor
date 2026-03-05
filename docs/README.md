# Mac Security Monitor

![Version](https://img.shields.io/badge/version-1.0.4-blue)
![Platform](https://img.shields.io/badge/platform-macOS%20Ventura%20%7C%20Sonoma-black)
![License](https://img.shields.io/badge/license-MIT-green)
![CI](https://img.shields.io/github/actions/workflow/status/Frapo78/mac-security-monitor/ci.yml?label=CI)

A lightweight integrity monitor for macOS that detects unexpected system changes using a baseline comparison approach.

Created by **Francesco Poltero**.

## What This Application Does

Mac Security Monitor runs **13 security checks by default** at every snapshot, plus **2 optional deep-network checks** when deep mode is enabled.

Default checks:

1. Non-Apple `launchd` services currently registered.
2. User LaunchAgents in `~/Library/LaunchAgents`.
3. System LaunchAgents in `/Library/LaunchAgents`.
4. System LaunchDaemons in `/Library/LaunchDaemons`.
5. Startup item metadata (hash, label, executable path, signature status).
6. Installed applications in `/Applications`.
7. Listening TCP services (what is waiting for network connections).
8. Non-Apple kernel extensions currently loaded.
9. Setuid binaries in standard system binary paths.
10. User login items.
11. Cron and periodic scheduled tasks.
12. Core macOS security controls (SIP, Gatekeeper, FileVault, firewall).
13. Installed configuration profiles.

Optional deep checks (only when `MSM_DEEP_NETWORK=1`):

1. Established TCP connections.
2. DNS/network configuration summary.

In short: the tool tracks persistence points, startup behavior, network exposure, and core platform protections, then compares them with your trusted baseline to detect changes.

## Why It Is Useful

- It watches "under-the-hood" system areas that can be silently changed by malicious scripts, unwanted tools, or persistence mechanisms.
- It helps detect risky changes that macOS may not clearly warn about in normal day-to-day use.
- It alerts you when sensitive security points change, such as startup services, scheduled tasks, login items, and listening network ports.
- It can reveal suspicious situations early, for example a hidden script opening a network port and exposing your Mac to remote intrusion.
- It gives you a clear before/after baseline comparison, so you can investigate unexpected changes before they become a bigger security problem.

## Features

- Baseline-based integrity monitoring
- Hourly background monitoring through `launchd`
- Interactive GUI alerts for detected changes
- Lightweight local logging
- Status, baseline management, and update CLI commands
- Optional OTA update checks and user-confirmed upgrades
- Safe reinstall command that preserves user data
- Bootstrap installer for one-line setup and disaster recovery
- Forensic-oriented snapshot sections with deterministic output ordering

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

## Release Validation Status

Version `1.0.4` is published with a controlled release approach to maximize reliability across different macOS setups.

Personally validated in local stress tests:

- repeated snapshot stability checks
- command smoke tests in isolated runtime paths
- installer/upgrade/reinstall logic validation

Community compatibility validation is requested for:

- macOS Ventura (13.x), Intel and Apple Silicon
- macOS Sonoma (14.x), Intel and Apple Silicon
- systems with MDM profiles or third-party security tools

Please run:

```bash
security-monitor self-test
```

Then report results in GitHub Issues using the compatibility report template.

Direct link:

- [Compatibility report issue template](https://github.com/Frapo78/mac-security-monitor/issues/new?template=compatibility-report.yml)

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

## First-Run Critical Check

After a clean installation, the first monitor cycle runs an additional critical security check.

If known high-risk issues are detected (for example disabled SIP, disabled Gatekeeper, or disabled firewall), Mac Security Monitor asks you how to proceed:

- `Keep Baseline Anyway`:
  - accept the current baseline and stop critical startup warnings
- `Keep Alert Active`:
  - keep critical warnings active until issues are remediated
- `Show Details`:
  - open the generated critical report and review findings

Critical report path:

- `~/.mac-security-monitor/state/critical-issues-last.txt`

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
security-monitor self-test
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

## Compatibility Feedback Window

For `v1.0.4`, maintain a 7-10 day compatibility feedback window before declaring the release fully validated across broader macOS environments.

Use the GitHub compatibility issue template to share test outcomes and edge cases.

## Logging

- Main log: `~/.mac-security-monitor/logs/monitor.log`
- LaunchAgent stdout: `~/.mac-security-monitor/logs/launchd.log`
- LaunchAgent stderr: `~/.mac-security-monitor/logs/launchd.err.log`

## Snapshot Stability

`maccheck` is designed to reduce false positives by default:

- Launchd output is normalized to labels only (no volatile PID/status columns).
- Network checks use a stable listening summary instead of transient connection noise.
- File-based sections are sorted for deterministic comparisons.

For deeper troubleshooting, you can enable extended network capture for one run:

```bash
MSM_DEEP_NETWORK=1 ~/.mac-security-monitor/bin/maccheck
```

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
