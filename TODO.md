# Pennykit Improvements

## Critical Bugs

- [ ] **Kickstart gruvbox.nvim broken syntax** — `lua/custom/plugins/init.lua` uses bare `opts = ...` without key-value pairs; will error at runtime
- [ ] **Lazygit add version mismatch** — `add_lazygit` hardcodes v0.60.0 while `update_lazygit` fetches latest; `add` should also be dynamic
- [ ] **`if true then return {} end` guards** — All non-default theme plugins (catppuccin, dracula, nord, solarized, tokyonight) use this pattern; means they're never loaded even when selected as the theme. `astroui.lua` sets colorscheme from `_local_theme.lua` but the corresponding plugin needs to be active. Fix: conditionally load based on `_local_theme.lua` content
- [ ] **`polish.lua` is dead code** — 5 lines, returns `{}`, unused. Either implement the late-stage hook pattern or delete the file

## Structural

- [ ] **Add lazy-lock.json for lazyvim and kickstart** — Only `astronvim_v6` has version-pinned plugins. Run `:Lazy lock` in the other two starters to prevent unexpected breakage
- [ ] **Split kickstart `init.lua`** — 1023-line monolithic file. Extract plugin configs into `lua/kickstart/plugins/*.lua` matching the astro pattern
- [ ] **CI/CD pipeline** — Add GitHub Actions:
  - Stylua linting on all `*.lua` files
  - Shellcheck on all `*.sh` and `bin/pennykit`
  - `:checkhealth` smoke test in headless nvim
  - Validate all lazy-lock.json files parse correctly
- [ ] **Yazi plugin loading commented out** — `configs/yazi/init.lua` has plugin loading `require` lines commented; unblock or document why
- [ ] **Dead configs audit** — `user.lua`, `languagetool.lua` (disabled), `none-ls.lua` (empty sources), `astrocore_rooter.lua` (disabled). Either implement, enable, or remove

## Feature Gaps

- [ ] **`pennykit doctor` command** — Health check that verifies:
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

- [ ] **Yazi prebuilt binary** — `update_yazi` builds from source via `cargo build --release` which takes 5-10 minutes. Add a fast-path that downloads prebuilt binaries from GitHub releases, with cargo build as fallback
- [ ] **Shellcheck compliance** — `bin/pennykit` (459 lines), `packages/extern.packages` (302 lines), installer scripts — none are shellcheck-clean. Add Shellcheck CI gate
- [ ] **Theme tmux handling is fragile** — `cmd_theme` mutates `configs/tmux/tmux.conf` with sed/cat, which can produce duplicate `set -g @plugin` lines on repeated theme switches. Switch to a template-based approach (like `_local_theme.lua`)
- [ ] **CLI UI polish** — `pennykit status` and `pennykit theme` output is plain text. Add color codes, box-drawing characters, and a consistent format. Consider `gum` or inline tput
- [ ] **`notes` function assumes `~/notes/` exists** — `pennykit_shell.functions:note()` writes to `~/notes/` but doesn't create the directory. Add `mkdir -p ~/notes` in the function
- [ ] **`editorconfig` not referenced from nvim** — EditorConfig file exists at `configs/editorconfig/editorconfig` (185 lines, 40+ filetypes) but nvim configs don't reference it. Add `vim.g.editorconfig = true` if not already set
- [ ] **Spell dictionary sync** — `spell/en.utf-8.add` and `spell/ru.utf-8.add` are under astro only. LazyVim and kickstart could also benefit. Either symlink or copy during theme/config switch

## Architecture

- [ ] **`lazy-lock.json` is gitignored** — `.gitignore` has `**/lazy-lock.json`. This means plugin versions float. Consider removing this rule for at least the primary config so collaborators get deterministic installs
- [ ] **Git submodules drift** — `.gitmodules` references `kickstart.git`, `astronvim.git`, `lazyvim.git` but directories on disk are `kickstart`, `astronvim_v6`, `lazyvim`. Verify submodule URLs are correct and pinned to specific commits
- [ ] **Container detection edge cases** — `PENNYKIT_ON_CONTAINER=false` is set before sourcing `extern.packages`, but `extern.packages` also sets it. This is confusing. Centralize detection in `check_system.sh` and export as readonly
- [ ] **Theme variables not centralized** — Theme `.conf` files define 13 variables each, but `cmd_theme` hardcodes which applications they affect. If a new app is added to the theme system, both the conf files AND the CLI need updating. Consider a declarative mapping

## Documentation

- [ ] **Generate keymap reference from config** — The keymap table in USE.md is hand-maintained. Consider a script that parses `lua/plugins/*.lua` for `desc` fields and generates the table automatically
- [ ] **Cross-starter compatibility matrix** — Document which plugins/keymaps/features work in all 3 starters vs astro-only vs lazyvim-only vs kickstart-only
- [ ] **Docker workflow docs** — Add a dedicated section for the 4 Dockerfiles: which to use when, build args, volume mounts, how themes work inside containers
