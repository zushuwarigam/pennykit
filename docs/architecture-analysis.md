# Pennykit Architecture Analysis

Generated: 2026-06-21
Analyzed branch: `rootless`
Analysis depth: Full project (150+ files, 5 entry points, 45+ scripts)

---

## 1. Project Overview

Pennykit is a **development environment orchestrator** — a dotfiles manager that installs system packages, configures 12+ applications, manages 3 Neovim starters, provides a unified theme system, and supports Docker-based dev containers.

**Three entry points:**

| Entry | Invocation | Purpose |
|-------|-----------|---------|
| `install` | `curl ... \| bash` | Bootstrap installer (clone repo, run setup) |
| `pennykit_install.sh` | Sourced by `install` | Post-clone: OS detection → package install → config symlinks |
| `bin/pennykit` | `pennykit status\|nvim\|theme\|extern\|doctor\|update\|branch\|clean` | CLI for day-to-day management |

---

## 2. Directory Map (Architectural View)

```
/pennykit/
├── install                    # [Entry 1] Bootstrap: clone → install → configure
├── pennykit_install.sh        # [Entry 2] Post-clone orchestrator
│
├── bin/pennykit               # [Entry 3] CLI (status, nvim, theme, extern, doctor, update, branch, clean)
│
├── lib/helpers.sh             # Shared: _curl, _wget, _verify_sha256, _is_deactivated, color output
│
├── scripts/
│   ├── package_installer.sh   # Pyramid installer: apt → pipx → npm → extern (+ dry-run, rootless)
│   ├── check_system.sh        # OS detection: PENNYKIT_OS_ID, PENNYKIT_OS_VERSION_CODENAME
│   ├── package_configure.sh   # Sources configs/config.* → creates symlinks
│   ├── apply_theme.py         # Python theme engine (reads TOML mapping)
│   ├── run_tests.sh           # Test runner: shellcheck → hadolint → BATS → pytest
│   ├── build/
│   │   ├── build_docker-image.sh    # Docker image builder
│   │   └── run_docker-container.sh  # Docker container runner
│   ├── install/
│   │   ├── package_installer.sh     # Pyramid installer
│   │   ├── check_system.sh          # OS detection
│   │   └── package_configure.sh     # Config symlinks
│   ├── test/
│   │   ├── run_tests.sh             # Test runner
│   │   ├── test_docker_install.sh   # Docker install testing
│   │   └── verify_docker_install.sh # Docker install verification
│   └── util/
│       ├── apply_theme.py           # Python theme engine
│       ├── gen_keymap_ref.py        # Neovim keymap reference
│       ├── dump_keymaps.lua         # Neovim keymap dumper
│       └── get_packages.sh          # Package listing
│
├── packages/
│   ├── apt.{default,admin,dev,pentest}    # System packages per tier
│   ├── npm.{default,admin,dev,pentest}    # npm global packages per tier
│   ├── pipx.{admin,dev,pentest}           # pipx packages per tier
│   ├── brew, brew.on_linux                # macOS Homebrew + Linux adapter
│   └── extern.packages                    # 14 external packages with add_/update_ functions
│
├── configs/
│   ├── config.*               # Executable bash scripts that create symlinks
│   ├── theme_mapping.toml     # Declarative theme mapping (11 apps, 5 operation types)
│   ├── themes/*.conf          # 6 themes: gruvbox (active), dracula, catppuccin, tokyonight, nord, solarized-dark
│   ├── extern.skip            # Deactivated packages (yazi, ueberzugpp)
│   ├── extern.problematic     # Failed extern packages (auto-generated, gitignored)
│   └── app-specific/          # bat, lazygit, lf, tmux, wezterm, yazi, editorconfig
│
├── nvim-starter/
│   ├── astronvim_v6/          # [Primary] AstroNvim v6 — 45+ plugin configs
│   ├── lazyvim/               # LazyVim starter
│   └── kickstart/             # Minimal kickstart.nvim
│
├── shell/
│   ├── pennykit.bash          # Bash shell integration entry point
│   ├── pennykit.zsh           # Zsh shell integration entry point
│   ├── exports.sh             # Environment variables
│   ├── aliases.sh             # Shell aliases
│   └── functions.sh           # Shell functions
│
├── Dockerfile.apt             # 5-stage build (os → pkgs → nvim → runtime → dev)
├── Dockerfile.brew            # 6-stage build (os → brew → pkgs → nvim → runtime → dev)
├── docker-compose.yml         # target=runtime, override.yml → target=dev
│
└── tests/
    ├── bats/                  # 44 BATS tests (6 files) — functional shell testing
    └── python/                # 7 pytest tests (5 fast + 2 slow Docker build)
```

---

## 3. Execution Flow

### Install Flow

```
User runs: bash install [-p all] [-r] [-f]
  │
  ├── Clone PENNYKIT_BRANCH (default: kit) into ~/.pennykit
  │
  └── source pennykit_install.sh
        ├── source lib/helpers.sh           (#0: most-sourced file, 4x)
        ├── source scripts/install/check_system.sh  (sets OS_ID + CODENAME)
        ├── mkdir ~/.npm-global; npm config set prefix
        ├── If ROOTLESS: mkdir ~/.local/{bin,opt,go}
        │
        ├── CASE $PENNYKIT_OS_ID:
        │     "debian" → ./scripts/install/package_installer.sh apt
        │     "macos"  → ./scripts/install/package_installer.sh brew
        │     *         → exit 1
        │
        └── source ./scripts/install/package_configure.sh
              └── source configs/config.* (one per app → creates symlinks)
```

### package_installer.sh Flow

```
package_installer.sh apt
  │
  ├── Detect SUDO (sudo if non-root)
  ├── Rootless mode: SUDO="", apt functions → no-ops (overrides dry-run)
  ├── Dry-run mode: all installers → echo commands
  │
  ├── Source: apt.default, npm.default, extern.packages
  │
  ├── IF PENNYKIT_APT_DEFAULT is set:
  │     ├── _apt_update && _apt_upgrade
  │     ├── _apt_install DEFAULT apt packages
  │     ├── source apt.default.postinst (rustup setup)
  │     ├── _add_or_skip DEFAULT extern packages
  │     │
  │     └── FOR each layer (admin/dev/pentest):
  │           ├── source apt.$layer → _apt_install (deduped)
  │           ├── source pipx.$layer → _pipx_install (deduped)
  │           ├── source npm.$layer  → _npm_install (deduped)
  │           └── _add_or_skip extern $layer packages
  │
  └── IF PENNYKIT_BREW_DEFAULT: brew install → brew cleanup
```

### CLI Flow (bin/pennykit)

```
pennykit <command> [args]
  │
  ├── status    → dashboard: branch, nvim config, theme, extern summary
  ├── nvim      → interactive Neovim starter switcher (clears nvim data)
  ├── theme
  │     ├── list → ls configs/themes/*.conf
  │     └── <name> → python3 scripts/apply_theme.py <name> (fallback: bash sed)
  ├── extern
  │     ├── deactivate|activate <pkg> → edit extern.skip
  │     ├── list-problematic|reset-problematic → manage extern.problematic
  │     └── default|admin|dev|pentest|all → update or install extern packages
  ├── doctor   → validate repo, symlinks, binaries, fonts
  ├── update   → git pull --rebase
  ├── branch   → show/switch git branch
  └── clean    → remove all pennykit symlinks + nvim data
```

---

## 4. Package System Architecture

### Pyramid Model

```
        ALL
     ┌──────┐
     │ADMIN │────────── DEFAULT + ADMIN
   ┌─┴──────┴─┐
   │   DEV    │────────── DEFAULT + DEV
 ┌─┴──────────┴─┐
 │   DEFAULT    │────────── ALWAYS installed (base layer)
 └──────────────┘
```

**ALL** = `layers=(admin dev pentest)` — note: admin is included in ALL.

### Package Manager Wrappers

Each manager has a consistent function interface:

| Function | Used For | Normal Mode | Dry-Run Mode | Rootless Mode |
|----------|---------|-------------|-------------|---------------|
| `_apt_install` | System packages | `$SUDO apt-get install -y` | Echo | No-op |
| `_pipx_install` | Python packages | `pipx install` | Echo | Echo |
| `_npm_install` | Node packages | `npm install` | Echo | Echo |
| `_brew_install` | macOS packages | `brew install` | Echo | Echo |

### Package File Convention

Every package file follows:
```bash
[[ -v _GUARD_VAR ]] && return || readonly _GUARD_VAR=1
PENNYKIT_<MANAGER>_<LAYER>+=("package-name")
```

### Deduplication

```bash
declare -A _seen_apt
declare -a _apt_pkgs=()
for layer in "${layers[@]}"; do
    source "./packages/apt.${layer}"
    local_arr="PENNYKIT_APT_${layer^^}[@]"
    for pkg in "${!local_arr}"; do
        [[ -z "${_seen_apt[$pkg]-}" ]] && _seen_apt[$pkg]=1 && _apt_pkgs+=("$pkg")
    done
done
```

### External Packages Pattern

14 packages, each with `add_<name>()` and `update_<name>()`:

| Package | Layer | Method | Destination |
|---------|-------|--------|-------------|
| fzf | DEFAULT | git clone + install | `~/.fzf/` |
| golang | DEFAULT | tarball download + extract | `~/.local/go/` |
| lazydocker | DEFAULT | tarball + SHA256 | `~/.local/bin/` |
| lazygit | DEFAULT | tarball + SHA256 | `~/.local/bin/` |
| nvim | DEFAULT | tarball + opt + symlink | `~/.local/opt/nvim/` |
| vivid | DEFAULT | .deb extract | `~/.local/bin/` |
| yazi | DEFAULT (deactivated) | prebuilt ZIP or source | `~/.local/bin/` |
| ueberzugpp | DEFAULT (deactivated) | .deb from OBS | `~/.local/bin/` |
| regex-tui | DEFAULT | `go install` | `~/go/bin/` |
| jqp | DEFAULT | `go install` | `~/go/bin/` |
| dive | ADMIN | .deb extract | `~/.local/bin/` |
| godap | ADMIN | git clone + `go install` | `~/go/bin/` |
| hadolint | ADMIN | binary download + SHA256 | `~/.local/bin/` |
| strace-tui | DEV | `cargo install` | `~/.cargo/bin/` |

---

## 5. Docker Build System

### Stages (Dockerfile.apt)

```
OS (debian:trixie)
  │ Install: build-essential, ca-certificates, curl, dialog, file, git, locales-all, procps, sudo, wget
  │ Create: non-root user (uid=1000) with passwordless sudo
  │ Set: locale ru_RU.UTF-8
  ▼
PKGS
  │ COPY: check_system.sh, package_installer.sh, lib/, packages/
  │ RUN: all apt + pipx + npm + extern packages (same pyramid as install)
  ▼
NVIM
  │ COPY: package_configure.sh, configs/, nvim-starter/
  │ RUN: config symlinks
  │ RUN: nvim --headless -c 'Lazy install' -c 'qa'
  ▼
RUNTIME (default docker target)
  │ COPY: all files — bin/, configs/, lib/, packages/, scripts/, nvim-starter/, shell configs
  ▼
DEV (docker-compose override target, command: /bin/bash)
```

### Cache Strategy

- Least-frequently-changed files copied first (`scripts/`, `lib/`, `packages/` → `pkgs` stage)
- Intermediate files (`nvim-starter/`, `configs/` → `nvim` stage)
- Everything else → `runtime` stage (most frequent changes)

---

## 6. Theme System

### Architecture

```
Python-first → Bash fallback

Python path:
  python3 scripts/apply_theme.py <name> [--dry-run]
    ├── Read: configs/theme_mapping.toml       (what to change, how)
    ├── Read: configs/themes/<name>.conf        (variable values)
    ├── For each app: apply operation type
    └── Write: configs/theme.conf

Bash fallback:
  Source theme.conf → hardcoded sed on each app file
```

### Operation Types (theme_mapping.toml)

| Type | Behavior | Used By |
|------|----------|---------|
| `template` | Write file with `%VAR%` substitution | wezterm, nvim |
| `sed` | Regex search/replace in file | bat, yazi, vivid, harlequin, lazygit |
| `sed_or_append` | Replace if grep matches, else append | shell_zsh |
| `sed_lf` | Handle literal \033 escape sequences | lf |
| `tmux_case` | Switch between minimal/catppuccin/dracula | tmux |

### Apps Affected (11)

wezterm, bat, yazi, vivid, harlequin, lazygit, nvim, tmux, lf, shell_bash, shell_zsh

### Available Themes (6)

gruvbox (active), dracula, catppuccin, tokyonight, nord, solarized-dark

---

## 7. Environment Variable Map

| Variable | Default | Setter | Readers | Effect |
|----------|---------|--------|---------|--------|
| `PENNYKIT_HOME` | `~/.pennykit` | install, many | Every script | Project root |
| `PENNYKIT_BRANCH` | `kit` | User/install | install | Git branch to clone |
| `PENNYKIT_PACKAGE_SET` | `DEFAULT` | `-p` flag | install, package_installer | Tier selector |
| `PENNYKIT_ROOTLESS` | unset | `-r` flag | install, package_installer | Skip apt → ~/.local/ |
| `PENNYKIT_DRY_RUN` | unset | User env | package_installer | Print commands |
| `PENNYKIT_LOCAL_DIR` | `~/.local` | package_installer | extern.packages | Rootless target |
| `PENNYKIT_OS_ID` | (detected) | check_system.sh | Installer scripts | OS type |
| `PENNYKIT_NVIM_CONFIG` | `astronvim_v6` | User | config.nvim | Starter choice |
| `PENNYKIT_FORCE` | `false` | `-f` flag | install, config.nvim | Force overwrite |
| `PENNYKIT_THEME` | `gruvbox` | theme cmd | status, doctor | Active theme |

---

## 8. Coding Conventions

### Shell Script Conventions

- **Shebang**: `#!/usr/bin/env bash` (portable)
- **Set flags**: `set -euo pipefail` on all executables
- **Quoting**: Always quote variables, double brackets `[[ ]]`
- **Guard pattern**: `[[ -v _GUARD ]] && return || readonly _GUARD=1` on sourced files
- **Shellcheck**: Pass `--severity=style`, all disable `SC1090,SC1091`
- **Output prefix**: `echo "  message"` (exactly two spaces)

### Function Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `_` | Internal/private | `_curl`, `_verify_sha256`, `_add_or_skip` |
| `cmd_` | CLI commands | `cmd_status`, `cmd_nvim`, `cmd_theme` |
| `add_`/`update_` | Extern package lifecycle | `add_dive`, `update_fzf` |
| `_install_` | Shared install logic | `_install_hadolint`, `_install_yazi_prebuilt` |
| `_apt_`, `_pipx_`, `_npm_`, `_brew_` | Package manager wrappers | `_apt_install`, `_brew_clean` |
| `apply_` | Theme operation types | `apply_template`, `apply_sed` |

### Variable Naming

| Pattern | Example | Scope |
|---------|---------|-------|
| `PENNYKIT_UPPER_SNAKE` | `PENNYKIT_HOME`, `PENNYKIT_APT_DEFAULT` | Global/exports |
| `_GUARD_VAR` | `_EXTERN_PACKAGES`, `_APT_DEFAULT` | Sourcing guards |
| `_lower_snake` | `_seen_apt`, `pkg`, `ver`, `archive` | Local variables |
| `PK_` | `PK_BASE_IMAGE_NAME` | Docker build config |

### Error Handling

- **Fail-fast**: `set -euo pipefail` catches most errors
- **Soft failures**: `|| true` pattern for optional operations
- **Problematic tracking**: `_mark_problematic`/`_clear_problematic` writes to `configs/extern.problematic`
- **Deactivation**: `_is_deactivated` checks `configs/extern.skip`
- **Cleanup on failure**: `|| { rm -f "$file"; return 1; }` pattern

---

## 9. Security Observations

### Download Verification (inconsistent)

| Level | Packages | Behavior |
|-------|----------|----------|
| **Strict** | hadolint, lazydocker, lazygit | Fail on SHA256 mismatch |
| **Warning** | golang, vivid, nvim | Warn on missing checksum, continue |
| **Audit** | yazi | Log hash for audit, continue |
| **None** | dive, fzf, godap, ueberzugpp, regex-tui, jqp, strace-tui | No verification |

### Other

- All downloads over HTTPS only
- GitHub API calls to `api.github.com` only
- Theme system validates `post_cmd` with path traversal guard
- OMB/ZSH install scripts verified before execution (shebang + function + name + install keyword check)
- No GPG verification, no certificate pinning
- `_cleanup_on_exit` helper exists but is dead code (never called)

---

## 10. Design Observations

### Strengths
- Strong shell coding standards (consistent guards, quoting, set flags)
- Well-structured package pyramid with clean deduplication
- Python + Bash dual-path architecture for theme system (graceful degradation)
- Multi-stage Docker builds with careful layer caching
- Comprehensive test suite (44 BATS + 7 pytest)
- Rootless mode as clean add-on without refactoring core
- Extern package state management (deactivation + problematic tracking)

### Issues & Inconsistencies
1. `_readlinkf` defined identically in 4+ files (missed shared abstraction)
2. SHA256 verification has 4 different behaviors across packages (no policy)
3. `_cleanup_on_exit` in `helpers.sh` is dead code
4. `go install ...@latest` is non-reproducible
5. Theme `post_cmd` path validation allows any absolute path starting with `/`
6. Rootless mode not explicitly tested for `go install`/`cargo install` packages
7. `ALL` layer includes admin + dev + pentest (documented as pyramid of DEFAULT+DEV+PENTEST)
8. No GPG verification for any external package source
9. `npm install -g` prefix must be user-local — done in penykit_install.sh but not enforced in package_installer.sh
10. BATS tests for extern packages mock network calls but don't test rootless mode
