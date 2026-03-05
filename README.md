# Mac Security Monitor

A lightweight baseline-based security monitoring tool for macOS.

Mac Security Monitor captures a security-focused snapshot of your Mac and compares it against a trusted baseline. When changes are detected, it alerts you through a macOS dialog and provides guided response actions.

Author: **Francesco Poltero**

Suggested first public release: **v1.0.0**

## Features

- Baseline-driven integrity monitoring
- Scheduled background checks through `launchd`
- Change detection with interactive GUI alert (AppleScript dialog)
- CLI status and baseline update commands
- Local-first design with user-space installation
- Safe installer and uninstaller scripts

## Architecture Overview

```text
mac-security-monitor/
├─ src/
│  ├─ maccheck                 # Collects current system security state
│  ├─ maccheck-alert           # Compares state with baseline and alerts user
│  └─ securitycheck-status     # Prints runtime/installation status
├─ installer/
│  ├─ install.sh               # Installs files, baseline, launch agent, CLI
│  └─ uninstall.sh             # Stops service and removes installed artifacts
├─ launchd/
│  └─ com.fra.securitycheck.plist  # LaunchAgent template
├─ gui/
│  └─ installer.applescript    # Optional GUI installer wrapper
├─ docs/
│  └─ README.md                # Local copy installed in ~/.mac-security-monitor/docs
├─ LICENSE
├─ CHANGELOG.md
├─ CONTRIBUTING.md
└─ .gitignore
```

## Installation

### Requirements

- macOS Ventura or newer
- `zsh`, `launchctl`, `osascript`
- Write access (or `sudo`) for `/usr/local/bin`

### Install from repository

```bash
cd /path/to/mac-security-monitor
./installer/install.sh
```

The installer can be run from any current working directory.

### Optional GUI installer

Run:

- `/absolute/path/to/mac-security-monitor/gui/installer.applescript`

## Installed Paths

Default base directory:

- `~/.mac-security-monitor`

Main installed files:

- `~/.mac-security-monitor/bin/maccheck`
- `~/.mac-security-monitor/bin/maccheck-alert`
- `~/.mac-security-monitor/bin/securitycheck-status`
- `~/.mac-security-monitor/baseline/current`
- `~/Library/LaunchAgents/com.fra.securitycheck.plist`

Installed global commands:

- `security-monitor`
- `security-monitor-update`

## CLI Usage

Check monitor status:

```bash
security-monitor
```

Regenerate baseline and show status:

```bash
security-monitor-update
```

## Monitoring Mechanism

1. `maccheck` collects a snapshot of selected security-relevant system data.
2. The LaunchAgent executes `maccheck-alert` every hour (`StartInterval=3600`) and at login (`RunAtLoad=true`).
3. `maccheck-alert` compares the new snapshot with baseline `~/.mac-security-monitor/baseline/current`.
4. If differences are found, a macOS dialog offers:
   - `Help`
   - `Show Details`
   - `Update Baseline`
   - `Disable Monitor`

## Security Philosophy

Mac Security Monitor is designed around simple, inspectable controls:

- Baseline comparison over opaque scoring
- User visibility and explicit approval for baseline updates
- Least privilege by default (user-space installation)
- Plain text artifacts for review and auditing

This tool does not replace endpoint security software. It provides an additional integrity signal for suspicious or unexpected system drift.

## Troubleshooting

If `security-monitor` is not found:

```bash
echo $PATH
ls -l /usr/local/bin/security-monitor
```

If LaunchAgent does not appear active:

```bash
launchctl list | grep com.fra.securitycheck
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist
```

Check monitor logs:

- `~/Library/Logs/mac-security-monitor.log`
- `~/Library/Logs/mac-security-monitor.err.log`

If baseline is missing:

```bash
~/.mac-security-monitor/bin/maccheck > ~/.mac-security-monitor/baseline/current
```

## Uninstall

```bash
cd /path/to/mac-security-monitor
./installer/uninstall.sh
```

This command:

- stops and unloads the LaunchAgent
- removes `~/.mac-security-monitor`
- removes `security-monitor` and `security-monitor-update`

## Compatibility

Target platforms:

- macOS Ventura
- macOS Sonoma
- Apple Silicon Macs

The project is shell-based and architecture-neutral for Apple Silicon and Intel Macs where command availability is compatible.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT License. See [LICENSE](./LICENSE).

## Author

Francesco Poltero
