# Pennykit

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zushuwarigam/pennykit/refs/heads/kit/install.sh)
```

## Tests

```bash
bash scripts/test/run_tests.sh
```

Runs shellcheck → hadolint → [BATS](https://github.com/bats-core/bats-core) → pytest.

The BATS helpers (`tests/bats/test_helper/bats-support`, `bats-assert`) are vendored — a fresh clone runs the suite directly, no extra setup. If a test tool is missing, the tier reports as skipped and the runner exits non-zero when nothing at all could run.

- **BATS**: `tests/bats/` — 174 tests across helpers, CLI, package installer, install script, config.shell/check_system, and external packages
- **pytest**: `tests/python/` — 11 theme tests for `apply_theme.py` (+2 slow Docker build tests excluded by default with `-m "not slow"`)
- **External packages**: `tests/bats/extern_packages.bats` mocks curl/wget with real SHA256 computation to verify `_verify_or_warn_sha256`, `_install_yazi_prebuilt`, `add_hadolint`, `_verify_release_checksum`, and `_add_or_skip` dispatch

## CI

`.github/workflows/ci.yml` runs the full suite on push/PR (shellcheck, hadolint, BATS, pytest). The Docker end-to-end install test (`scripts/test/test_docker_install.sh --verify`) is available as a manual `workflow_dispatch` job.
