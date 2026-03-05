# Contributing to Mac Security Monitor

Thank you for contributing.

Project author and maintainer: **Francesco Poltero**

## Scope

Contributions should improve stability, maintainability, and security visibility without introducing unnecessary complexity.

## Development Principles

- Keep scripts POSIX-friendly where practical and compatible with macOS `zsh`.
- Use clear English for all documentation, comments, commit messages, and user-facing strings.
- Avoid hardcoded absolute user paths.
- Preserve the baseline comparison model unless a change clearly improves security or reliability.
- Prefer simple and auditable logic over heavy abstractions.

## Repository Conventions

- Runtime scripts live in `src/`.
- Installer and uninstaller scripts live in `installer/`.
- LaunchAgent templates live in `launchd/`.
- User-facing documentation lives in `README.md` and `docs/README.md`.

## Pull Request Checklist

Before opening a pull request:

1. Ensure scripts are executable when needed (`chmod +x`).
2. Validate installation flow on a clean macOS user profile if possible.
3. Run and verify:
   - `./installer/install.sh`
   - `security-monitor`
   - `security-monitor-update`
   - `./installer/uninstall.sh`
4. Confirm all text is English-only.
5. Update `CHANGELOG.md` when behavior changes.

## Security Contributions

For security-sensitive improvements:

- Describe threat scenario and expected impact.
- Explain how the change affects baseline integrity and false positive risk.
- Keep user actions explicit (no silent destructive behavior).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
