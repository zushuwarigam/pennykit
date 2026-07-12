# Pennykit

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zushuwarigam/pennykit/refs/heads/kit/install.sh)
```

## Tests

```bash
bash scripts/run_tests.sh
```

Runs shellcheck → hadolint → [BATS](https://github.com/bats-core/bats-core) → pytest.

- **BATS**: `tests/bats/` — 43 tests across helpers, CLI, package installer, install script, config.shell, and external packages
- **pytest**: `tests/python/` — 5 tests for `apply_theme.py` (+2 slow Docker build tests skipped by default with `-m "not slow"`)
- **External packages**: `tests/bats/extern_packages.bats` mocks curl/wget with real SHA256 computation to verify `_verify_or_warn_sha256`, `_install_yazi_prebuilt`, `add_hadolint`, and `_add_or_skip` dispatch
