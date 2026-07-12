# Pennykit — Agent Instructions

## What this is

Development environment orchestrator. Dotfiles manager with Neovim (3 starters: AstroNvim v6 primary, LazyVim, kickstart), unified theme system across 12+ apps, shell integration, external package management, and Docker dev containers.

## Key commands

```bash
bash scripts/test/run_tests.sh     # Full suite: shellcheck → hadolint → BATS → pytest
python3 -m pytest tests/python/ -v -m "not slow"   # Python tests only (skip Docker builds)
bats tests/bats/*.bats             # BATS tests only
```

- Slow Docker build tests: `@pytest.mark.slow` — skipped by default, run with `-m "slow"`
- BATS uses generated `tests/bats/test_helper/*/load.bash` (in `.gitignore`); install bats via `npm install` (in `package.json`)
- Rootless mode: `PENNYKIT_ROOTLESS=1 bash scripts/install/package_installer.sh apt` skips apt tiers, installs extern packages to `~/.local/`

## Project structure

| Path | Purpose |
|------|---------|
| `bin/pennykit` | CLI entry point (thin dispatcher) |
| `lib/helpers.sh` | Shared: `_curl`, `_wget`, `_verify_sha256`, `_is_deactivated`, colored output |
| `scripts/` | Build, install, theme, test, config, Docker |
| `packages/` | `apt.{default,dev,admin,pentest}`, `npm.{default,...}`, `pipx.{default,...}`, `brew`, `extern.packages` |
| `configs/` | Per-app configs + `themes/` + `theme_mapping.toml` + `extern.skip` (deactivated pkgs) |
| `nvim-starter/` | `astronvim_v6/`, `lazyvim/`, `kickstart/`, `vimrc.base` |
| `shell/` | Shell integration: `pennykit.bash`, `pennykit.zsh`, `exports.sh`, `aliases.sh`, `functions.sh` |
| `docker.config` | Docker build config: sets `PROJECT_NAME`, `PK_BASE_IMAGE_NAME`, `PK_BASE_IMAGE_TAG` |
| `install.sh` | Bootstrap script: clones repo and runs `pennykit_install.sh` |

## Package layers

DEFAULT always installed. `-p` flag selects higher tiers (ADMIN, DEV, PENTEST, ALL). Pyramid: each tier adds to the previous. ALL = DEFAULT + admin + dev + pentest. DEV = DEFAULT + dev. PENTEST = DEFAULT + dev + pentest.

## Architecture notes

- **Theme system**: Python-first (`scripts/util/apply_theme.py` reads `configs/theme_mapping.toml`), falls back to bash sed in `lib/cmd_theme.sh`. Needs Python 3.11+ or `tomli` package.
- **External packages**: `packages/extern.packages` defines `add_<pkg>()` / `update_<pkg>()` functions. Deactivation via `configs/extern.skip`. Problematic state stored in `configs/extern.problematic`.
- **OS detection**: `scripts/install/check_system.sh` sets `$PENNYKIT_OS_ID` (debian/macos/other) and `$PENNYKIT_OS_VERSION_CODENAME`. Controls conditional package paths (eza/rustup only on trixie; harlequin via pipx only on trixie).
- **Docker**: Multi-stage builds (os → pkgs → nvim → runtime → dev). Use `docker compose up -d` or `scripts/build/build_docker-image.sh`. The `docker-compose.override.yml` sets build target to `dev`.
- **Nvim config switching**: Clears `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` on switch.

## Conventions

- Shell scripts: `set -euo pipefail`, pass `shellcheck --severity=style`
- `PENNYKIT_DRY_RUN=1` env var prints install commands without executing (works for both `scripts/install/package_installer.sh` and `scripts/build/build_docker-image.sh`)
- `_add_or_skip` wraps package install to check deactivation
- `_is_deactivated` checks `configs/extern.skip` (one package name per line, `#` comments)
- `scripts/util/get_packages.sh` lists all packages with descriptions (`grep -rnI "pkg.*desc"`)
- Docker build verification: `scripts/test/verify_docker_install.sh` and `scripts/test/test_docker_install.sh` — output goes to `logs/`

## Gotchas

- `pennykit doctor` needs a git repo initialized in `$PENNYKIT_HOME`
- Theme `--dry-run` flag only supported via Python apply (not bash fallback)
- BATS uses `load 'test_helper/bats-support/load'` — these helpers are generated, see `.gitignore`
- `python3` with tomllib required for theme apply; bash fallback is basic sed
- Install script clones branch from `PENNYKIT_BRANCH` env var (defaults to `kit`)
- Container detection reads `/etc/os-release`; Homebrew skipped on Linux unless `brew.linux` sourced
- Vivid/LS_COLORS, harlequin, and bat aliases are patched via sed in `shell/exports.sh`/`shell/aliases.sh`
- Blue screen during install: sudo's `env_reset` drops `DEBIAN_FRONTEND`/`DEBCONF_FRONTEND`. Every `$SUDO apt` call in `scripts/install/package_installer.sh` and `packages/extern.packages` must inline env vars: `$SUDO DEBIAN_FRONTEND=noninteractive DEBCONF_FRONTEND=noninteractive NEEDRESTART_MODE=a apt ...`
- Rootless mode (`PENNYKIT_ROOTLESS=1`): apt tiers are skipped entirely. Extern packages (Go, Neovim, dive, vivid, ueberzugpp) install to `$PENNYKIT_LOCAL_DIR` (default `~/.local/`) instead of system paths. Set via `install.sh -r` or `PENNYKIT_ROOTLESS=1` env var.
