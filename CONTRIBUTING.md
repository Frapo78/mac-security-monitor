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
- Shared shell utilities: `src/lib/common.sh`
- Command modules: `src/commands/`
- Installer lifecycle: `installer/`
- LaunchAgent template: `launchd/`
- Docs: `README.md` and `docs/README.md`
- CI checks: `.github/workflows/ci.yml`

## Local Validation Before Pull Request

Run:

```bash
zsh -n src/security-monitor src/security-monitor-update src/securitycheck-status src/maccheck src/maccheck-alert src/lib/common.sh src/commands/*.sh
zsh -n installer/install.sh installer/uninstall.sh
zsh -n install.sh
plutil -lint launchd/com.frapo78.securitycheck.plist
```

If available:

```bash
shellcheck -s bash -x src/security-monitor src/security-monitor-update src/securitycheck-status src/maccheck src/maccheck-alert src/lib/common.sh src/commands/*.sh installer/install.sh installer/uninstall.sh install.sh
```

Recommended local stability smoke test:

```bash
TEST_BASE=/tmp/msm-ci-smoke
rm -rf "$TEST_BASE"
mkdir -p "$TEST_BASE/bin" "$TEST_BASE/logs" "$TEST_BASE/state" "$TEST_BASE/baseline"
cp -R src/. "$TEST_BASE/bin/"
find "$TEST_BASE/bin" -type f \( -name "*.sh" -o -name "maccheck" -o -name "maccheck-alert" -o -name "security-monitor" -o -name "security-monitor-update" -o -name "securitycheck-status" \) -exec chmod 0755 {} +
cp VERSION "$TEST_BASE/VERSION"
BASE_DIR="$TEST_BASE" "$TEST_BASE/bin/security-monitor" update-baseline
BASE_DIR="$TEST_BASE" "$TEST_BASE/bin/security-monitor"
```

Recommended user-level health check:

```bash
security-monitor self-test
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

## Compatibility Reports

For platform-specific issues, use the GitHub compatibility issue template:

- `.github/ISSUE_TEMPLATE/compatibility-report.yml`

## License

By contributing, you agree to license your contributions under the MIT License.
