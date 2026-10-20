# Test Plan: Complete Coverage for Pennykit

> **Goal:** Achieve comprehensive test coverage across all Pennykit subsystems

**Current state:** 55 BATS tests (all passing), 5 pytest tests (skipped, no python3 env), hadolint with style warnings only

---

## Phase 1: High-Priority Gaps (Core CLI Features)

### Task 1: Test `cmd_nvim` — Neovim Config Switcher

**Files:**
- Source: `bin/pennykit:103-142`
- Test: `tests/bats/pennykit.bats`

**Use cases to test:**
- Shows available nvim configs (astronvim_v6, lazyvim, kickstart)
- Selects a config → creates correct symlink at `~/.config/nvim`
- Selects "Disable nvim config" → removes symlink
- Switching configs removes old `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`
- `_nvim_config_type` returns correct type for: symlink, external_symlink, directory, none
- Handles missing `~/.config/nvim` directory gracefully
- Handles force flag for existing directory config

---

### Task 2: Test `_update_or_skip` — Extern Package Dispatch

**Files:**
- Source: `bin/pennykit:301-328`
- Test: `tests/bats/extern_packages.bats` or new `tests/bats/dispatch.bats`

**Use cases to test:**
- Calls `add_<pkg>()` when package not installed
- Calls `update_<pkg>()` when package is installed
- Skips deactivated packages via `_is_deactivated`
- Marks failure in `extern.problematic` when install fails
- Clears `extern.problematic` on successful install

---

### Task 3: Test `cmd_extern` with Package Sets

**Files:**
- Source: `bin/pennykit:422-453`
- Test: `tests/bats/pennykit.bats`

**Use cases to test:**
- `pennykit extern default` — installs/updates DEFAULT extern packages
- `pennykit extern admin` — installs/updates ADMIN extern packages
- `pennykit extern dev` — installs/updates DEV extern packages
- `pennykit extern pentest` — installs/updates PENTEST extern packages
- `pennykit extern all` — installs/updates all extern packages
- `pennykit extern` (no args) — default update
- `pennykit extern` with retry-problematic flag

---

### Task 4: Test `cmd_theme` Apply — Full Flow

**Files:**
- Source: `bin/pennykit:146-297`
- Test: `tests/bats/pennykit.bats`

**Use cases to test:**
- `pennykit theme show` — shows current theme from `theme.conf`
- `pennykit theme <name>` — applies theme via Python (mocked)
- `pennykit theme <name>` — applies theme via bash fallback
- `pennykit theme <name>` with invalid name (path traversal)
- `pennykit theme <name>` with missing theme file
- Bash fallback: apply wezterm (sed), bat (sed), yazi (sed), vivid (sed), harlequin (sed), lazygit (sed), nvim (sed), tmux (tmux_case), lf (sed_lf), OMB (sed), OMZ (sed_or_append)

---

## Phase 2: High-Priority Infrastructure Gaps

### Task 5: Test `scripts/install/package_configure.sh` (entirely)

**Files:**
- Source: `scripts/install/package_configure.sh`
- Test: `tests/bats/package_configure.bats` (new)

**Use cases to test:**
- Sources `helpers.sh` successfully
- Iterates over `configs/config.*` files
- Each individual config file can be sourced without error
- Handles missing `configs/` directory
- Reports errors from individual config files without aborting

---

### Task 6: Test `config.nvim`

**Files:**
- Source: `configs/config.nvim`
- Test: `tests/bats/config_nvim.bats` (new)

**Use cases to test:**
- Creates symlink for `nix` config (astronvim_v6, lazyvim, kickstart)
- Backs up existing `~/.config/nvim` directory when it's not a symlink
- Respects `PENNYKIT_FORCE` flag
- Handles `PENNYKIT_REMOVE_NVIM_DATA` removal
- Installs tree-sitter parsers via nvim headless
- Idempotent on re-run

---

### Task 7: Test `detect_os` — OS Detection

**Files:**
- Source: `scripts/install/check_system.sh`
- Test: `tests/bats/check_system.bats` (new)

**Use cases to test:**
- Detects debian trixie from mock `/etc/os-release`
- Detects debian bookworm from mock `/etc/os-release`
- Detects ubuntu noble from mock `/etc/os-release`
- Detects ID_LIKE debian (e.g. mint, pop)
- Detects macOS via OSTYPE mock
- Falls back to "other" for unrecognized OS
- Handles missing `/etc/os-release`
- Exports `PENNYKIT_OS_ID` and `PENNYKIT_OS_VERSION_CODENAME`

---

### Task 8: Test pipx/npm layer processing

**Files:**
- Source: `scripts/install/package_installer.sh:133-167`
- Test: `tests/bats/package_installer.bats` (add to existing)

**Use cases to test:**
- Sources pipx package files for each tier
- Calls `pipx install` for each package
- Sources npm package files for each tier
- Calls `npm install -g` for each package
- Deduplicates across tiers via `_seen_pipx` / `_seen_npm`
- Dry-run prints commands without executing

---

## Phase 3: Medium Priority

### Task 9: Test shell integration files

**Files:**
- Source: `shell/pennykit.bash`, `shell/pennykit.zsh`, `shell/exports.sh`, `shell/functions.sh`
- Test: `tests/bats/shell_integration.bats` (new)

**Use cases to test:**
- `shell/pennykit.bash` sources all three sub-files
- `shell/pennykit.zsh` sources all three sub-files
- `shell/exports.sh` sets PATH correctly (Go, local, Cargo, OPAM, npm, pennykit)
- `shell/exports.sh` generates LS_COLORS via vivid
- `shell/aliases.sh` defines core aliases (v, vi, vim)
- `shell/aliases.sh` defines git/docker aliases
- `shell/functions.sh` `mkcd` creates dir and switches
- `shell/functions.sh` `bak` creates `.bak`
- `shell/functions.sh` `note` with no args creates inbox entry
- `shell/functions.sh` `note -d` appends timesheet

---

### Task 10: Test remaining config files

**Files:**
- Source: `configs/config.{bat,tmux,lf,yazi,lazygit,editorconfig,wezterm,fzf}`
- Test: `tests/bats/config_files.bats` (new)

**Use cases to test per config:**
- Creates the correct symlink target
- Handles existing symlink (unlink first)
- Handles existing regular file (backup first)
- Respects `PENNYKIT_FORCE` flag
- Idempotent on re-run

---

### Task 11: Test Python theme engine edge cases

**Files:**
- Source: `scripts/util/apply_theme.py`
- Test: `tests/python/test_apply_theme.py` (add)

**Use cases to test:**
- Missing `theme_mapping.toml` produces readable error
- Invalid TOML in mapping produces readable error
- sed operations (bat, vivid, harlequin, lazygit, shell) — mock config files, verify regex replacement
- sed_lf operation — verify escape sequence replacement for lf
- tmux_case operation — verify tmux config writing
- sed_or_append operation — verify append when grep doesn't match
- Dry-run does NOT modify any files
- `post_cmd` validation (path traversal guard)

---

### Task 12: Test `cmd_doctor` error paths

**Files:**
- Source: `bin/pennykit`
- Test: `tests/bats/pennykit.bats` (add)

**Use cases to test:**
- Missing git repo → reports error
- Missing `extern.packages` → reports warning
- Missing theme → reports warning
- Missing Nerd Font → reports info
- Missing expected symlinks (nvim, tmux, bat) → reports each

---

## Phase 4: Docker & Integration Tests

### Task 13: Test `verify_docker_install.sh` and `test_docker_install.sh`

**Files:**
- Source: `scripts/verify_docker_install.sh`, `scripts/test_docker_install.sh`
- Test: ShellCheck + hadolint coverage (no fail on style)

**Hadolint issues to fix (style):**
- `Dockerfile.apt`: DL3008 (pin versions), DL3002 (last USER not root), DL3059 (consolidate RUN)
- `Dockerfile.brew`: DL3008, DL3002, DL3059, SC2016
- `Dockerfile.dev-debian_bookworm`: DL3008
- `Dockerfile.dev-debian_trixie`: DL3008

---

## Implementation Order

| Phase | Tasks | Priority | Estimated tests |
|-------|-------|----------|----------------|
| 1a | Task 1 (`cmd_nvim`) | Critical | 6 |
| 1b | Task 2 (`_update_or_skip`) | Critical | 5 |
| 1c | Task 3 (`cmd_extern` sets) | High | 6 |
| 1d | Task 4 (`cmd_theme` apply) | High | 8 |
| 2a | Task 5 (`package_configure.sh`) | High | 4 |
| 2b | Task 6 (`config.nvim`) | High | 5 |
| 2c | Task 7 (`detect_os`) | High | 7 |
| 2d | Task 8 (pipx/npm layers) | High | 5 |
| 3a | Task 9 (shell integration) | Medium | 10 |
| 3b | Task 10 (config files) | Medium | 9 |
| 3c | Task 11 (Python edge cases) | Medium | 7 |
| 3d | Task 12 (doctor error paths) | Medium | 5 |
| 4 | Task 13 (Docker) | Low | 0 (lint fixes) |

**Total new tests:** ~77

**Percent coverage increase:** From 55 tests covering ~40% of components → ~132 tests covering ~95% of components
