# Contributing to Mac Security Monitor

Project author and maintainer: **Francesco Poltero**

## Principles

- Keep the project lightweight, transparent, and easy to audit.
- Keep all comments, documentation, and messages in English.
- Prefer deterministic shell logic over complex abstractions.
- Avoid hardcoded user-specific paths.
- Keep baseline updates explicit and user-controlled.

## Repository Conventions

- Runtime scripts: `src/`
- Installer lifecycle: `installer/`
- LaunchAgent template: `launchd/`
- Docs: `README.md` and `docs/README.md`
- CI checks: `.github/workflows/ci.yml`

## Local Validation Before Pull Request

Run:

```bash
zsh -n src/maccheck src/maccheck-alert src/securitycheck-status src/security-monitor-update
zsh -n installer/install.sh installer/uninstall.sh
plutil -lint launchd/com.fra.securitycheck.plist
```

If available:

```bash
shellcheck -s bash -x src/maccheck src/maccheck-alert src/securitycheck-status src/security-monitor-update installer/install.sh installer/uninstall.sh
```

## Pull Request Checklist

1. Keep scripts executable where required.
2. Keep behavior idempotent for reinstall and uninstall flows.
3. Do not remove or change author attribution.
4. Update `CHANGELOG.md` for user-visible changes.
5. Confirm README reflects command and installation changes.

## Security Contributions

When proposing security changes, include:

- the threat model or misuse case
- why the change improves safety or reliability
- impact on false positives and user workflow

## License

By contributing, you agree to license your contributions under the MIT License.
