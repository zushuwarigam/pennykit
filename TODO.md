# Pennykit Improvements

## Critical Bugs

- [x] **Kickstart gruvbox.nvim broken syntax** — `lua/custom/plugins/init.lua` uses bare `opts = ...` without key-value pairs; will error at runtime
- [x] **Lazygit add version mismatch** — `add_lazygit` hardcodes v0.60.0 while `update_lazygit` fetches latest; `add` should also be dynamic
- [x] **`if true then return {} end` guards** — All non-default theme plugins (catppuccin, dracula, nord, solarized, tokyonight) use this pattern; means they're never loaded even when selected as the theme. `astroui.lua` sets colorscheme from `_local_theme.lua` but the corresponding plugin needs to be active. Fix: conditionally load based on `_local_theme.lua` content
- [x] **`polish.lua` is dead code** — 5 lines, returns `{}`, unused. Either implement the late-stage hook pattern or delete the file

## Structural

- [x] **Add lazy-lock.json for lazyvim and kickstart** — Generated via `:Lazy lock` headless; all 3 starters now have pinned plugin versions
- [ ] **Split kickstart `init.lua`** — 1023-line monolithic file. Extract plugin configs into `lua/kickstart/plugins/*.lua` matching the astro pattern
- ~~**CI/CD pipeline**~~ — Not needed (personal project, no collaboration)
- [x] **Yazi plugin loading commented out** — Uncommented `require` lines for git, fzf, rg plugins in `configs/yazi/init.lua`
- [x] **Dead configs audit** — `user.lua` (active, populated), `languagetool.lua` (disabled by design), `none-ls.lua` (now guarded), `astrocore_rooter.lua` (active)

## Feature Gaps

- [x] **`pennykit doctor` command** — Health check that verifies:
  - Symlinks (nvim, wezterm, bat, etc.)
  - Required binaries (nvim, git, rg, fzf, lazygit, etc.)
  - Theme files consistency
  - Git submodule status
  - Mason tool installation status
  - Nerd Font detection
- [ ] **Startup profiling baseline** — Document expected startup times per starter:
  ```bash
  nvim --startuptime /tmp/startup.log -c 'quit'
  ```
  Include in README or USE.md with `:Lazy profile` results
- [ ] **Auto-session for LazyVim** — Only AstroNvim has `resession.nvim`. LazyVim starter has zero session management
- [ ] **Standardize fuzzy picker** — Project uses fzf-lua (astro default), telescope (configs present), and snacks.picker (lazy-lock.json includes snacks). Pick one primary and document the migration
- [ ] **New language onboarding doc** — Steps to add a new language (LSP, formatter, treesitter parser, test adapter, debug adapter) in a single documented workflow

## Quality of Life

- [x] **Yazi prebuilt binary** — Added fast-path that downloads prebuilt binaries from GitHub releases, with cargo build as fallback
- [x] **Shellcheck compliance** — All shell scripts now pass `shellcheck --severity=style` clean. Includes adding SC1090/SC1091 directives for sourced files and fixing SC2002/SC2207 issues.
- [x] **Theme tmux handling is fragile** — Replaced sed-based mutation with separate `tmux_theme.conf` fully overwritten per theme (same pattern as `_local_theme.lua`)
- [x] **CLI UI polish** — Added tput-based color to `pennykit status` and `pennykit theme` (green for active, yellow for warnings, cyan for labels)
- [x] **`notes` function assumes `~/notes/` exists** — Added `mkdir -p` at function start
- [x] **`editorconfig` not referenced from nvim** — Added `vim.g.editorconfig = true` to lazyvim and kickstart
- [x] **Spell dictionary sync** — Symlinked lazyvim/spell and kickstart/spell → astronvim_v6/spell

## Architecture

- [x] **`lazy-lock.json` is gitignored** — Removed `**/lazy-lock.json` from `.gitignore`; astronvim lock file now trackable
- [x] **Git submodules drift** — Dead `.git` submodule directories removed; actual configs stay as-is
- [x] **Container detection edge cases** — Centralized in `check_system.sh`, sourced from both `pennykit_install.sh` and `bin/pennykit`
- [ ] **Theme variables not centralized** — Theme `.conf` files define 13 variables each, but `cmd_theme` hardcodes which applications they affect. If a new app is added to the theme system, both the conf files AND the CLI need updating. Consider a declarative mapping

## Documentation

- [ ] **Generate keymap reference from config** — The keymap table in USE.md is hand-maintained. Consider a script that parses `lua/plugins/*.lua` for `desc` fields and generates the table automatically
- [ ] **Cross-starter compatibility matrix** — Document which plugins/keymaps/features work in all 3 starters vs astro-only vs lazyvim-only vs kickstart-only
- [ ] **Docker workflow docs** — Add a dedicated section for the 4 Dockerfiles: which to use when, build args, volume mounts, how themes work inside containers
