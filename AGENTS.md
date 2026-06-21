# Pennykit — Agent Instructions

## What this is

Development environment orchestrator. Dotfiles manager with Neovim (3 starters: AstroNvim v6 primary, LazyVim, kickstart), unified theme system across 12+ apps, shell integration, external package management, and Docker dev containers.

## Key commands

```bash
bash scripts/run_tests.sh          # Full suite: shellcheck → hadolint → BATS → pytest
python3 -m pytest tests/python/ -v -m "not slow"   # Python tests only (skip Docker builds)
bats tests/bats/*.bats             # BATS tests only
```

- Single slow Docker build test marker: `@pytest.mark.slow` — skipped by default, `-m "slow"`
- BATS tests use `test_helper/` dirs with generated `load.bash` (in `.gitignore`)

## Project structure

| Path | Purpose |
|------|---------|
| `bin/pennykit` | CLI entry point |
| `lib/helpers.sh` | Shared: `_curl`, `_wget`, `_verify_sha256`, `_is_deactivated`, colored output |
| `scripts/` | Build, install, theme, test, config, Docker |
| `packages/` | `apt.*`, `npm.*`, `pipx.*`, `brew`, `extern.packages` |
| `configs/` | Per-app configs + `themes/` + `theme_mapping.toml` |
| `nvim-starter/` | `astronvim_v6/`, `lazyvim/`, `kickstart/`, `vimrc.base` |
| `tests/bats/` | 6 test files covering helpers, CLI, package installer, install, config, extern |
| `tests/python/` | `test_apply_theme.py`, `test_docker_build.py` |

## Architecture notes

- **Theme system**: Python-first (`scripts/apply_theme.py` reads `configs/theme_mapping.toml`), falls back to bash sed in `bin/pennykit`. Needs Python 3.11+ or `tomli` package.
- **Package layers**: DEFAULT always installed. ADMIN/DEV/PENTEST/ALL selected via `-p` flag on install. Pyramid: ADMIN adds to DEFAULT, DEV adds to default → dev, PENTEST = DEV → pentest.
- **External packages**: `packages/extern.packages` defines `add_<pkg>()` / `update_<pkg>()` functions. Deactivation via `configs/extern.skip`.
- **OS detection**: `scripts/check_system.sh` sets `$PENNYKIT_OS_ID` (debian/macos/other) and `$PENNYKIT_OS_VERSION_CODENAME`. Important for correct package paths (eza/rustup only on trixie).
- **Docker**: Multi-stage builds (os → pkgs → nvim → runtime → dev). Use `docker compose up -d` or `scripts/build_docker-image.sh`.
- **Nvim config switching**: Clears `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` on switch.

## Conventions

- Shell scripts: `set -euo pipefail`, pass `shellcheck --severity=style`
- `PENNYKIT_DRY_RUN=1` env var to print install commands without executing
- `_add_or_skip` wraps package install to check deactivation
- `_is_deactivated` checks `configs/extern.skip` (one package name per line, `#` comments)

## Gotchas

- `pennykit doctor` needs a git repo initialized in `$PENNYKIT_HOME`
- Theme `--dry-run` flag only supported via Python apply (not bash fallback)
- BATS uses `load 'test_helper/bats-support/load'` — these helpers are generated, see `.gitignore`
- `python3` with tomllib required for theme apply; bash fallback is basic sed
- Container detection reads `/etc/os-release`; Homebrew skipped on Linux unless `brew.on_linux` sourced
- Vivid/LS_COLORS, harlequin, and bat aliases are patched via sed in `pennykit_shell.exports`/`.alias`
