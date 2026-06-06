# Pennykit Usage Guide

## Composition Overview

Pennykit is a **development environment orchestrator** built around Neovim with three starter configurations (AstroNvim v6 primary, LazyVim, kickstart.nvim). It integrates shell tooling, file managers, terminal emulators, Docker workflows, and a unified theme system across 12+ applications.

---

## Plugin Best Practices

### 1. Plugin Manager: lazy.nvim

```lua
{
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = { ... },
  keys = { ... },
  dependencies = { ... },
}
```

| Trigger | Use Case |
|---------|----------|
| `lazy = false, priority = 1000` | Colorschemes, core UI |
| `event = { "BufReadPre", "BufNewFile" }` | Treesitter, LSP |
| `event = "VeryLazy"` | Non-critical UI |
| `cmd = "SomeCommand"` | Command-triggered |
| `ft = "python"` | Filetype-specific |
| `keys = { ... }` | Keymap-triggered |

Use `opts` instead of `config` when possible. Only `config` when imperative setup logic is needed.

### 2. Completion: blink.cmp

```lua
sources = {
  default = { "lsp", "path", "snippets", "buffer" },
  per_filetype = {
    lua = { inherit_defaults = true, "lazydev" },
  },
  providers = {
    lsp = { fallbacks = { "buffer" } },
    buffer = { score_offset = -3 },
  },
}
keymap = { preset = "default" }
```

### 3. Fuzzy Finding

| Plugin | When | Keymaps |
|--------|------|---------|
| **fzf-lua** (AstroNvim default) | General purpose | `<Leader>ff` files, `<Leader>fg` grep, `<Leader>fb` buffers |
| **telescope.nvim** | Fallback | Same conventions |
| **snacks.nvim picker** | Modern alternative | `Snacks.picker.smart()` |

### 4. LSP & Formatting

**Priority**: LSP built-in > null-ls/none-ls > conform.nvim

```lua
-- Go example: language-specific, ft-loaded
{
  "ray-x/go.nvim",
  ft = { "go", "gomod", "gosum", "gowork" },
  opts = {
    gofmt = "gofumpt",
    lsp_inlay_hints = { enable = true },
    dap_debug = true,
    test_runner = "go",
  },
}

-- conform for non-LSP formatting
format_on_save = { timeout_ms = 500, lsp_format = "fallback" }
```

### 5. Debugging (nvim-dap)

| Key | Action |
|-----|--------|
| `<F5>` | Continue / Start |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<Leader>b` | Toggle breakpoint |
| `<Leader>B` | Conditional breakpoint |
| `<Leader>dt` | Toggle DAP UI |
| `<Leader>de` | Evaluate expression |
| `<Leader>dr` | Re-run last session |

Adapters: `codelldb` (C/C++), `debugpy` (Python — auto-detects `venv`/`.venv`), `delve` (Go via go.nvim). All auto-installed via mason.

### 6. Testing (neotest)

| Key | Action |
|-----|--------|
| `<Leader>tr` | Run nearest test |
| `<Leader>tf` | Run test file |
| `<Leader>ts` | Toggle summary |
| `<Leader>tS` | Stop |

Supported: `pytest` (Python, `justMyCode=false`), `go test` (Go).

### 7. Git Workflow

```lua
-- gitsigns: line-level awareness
on_attach = function(bufnr)
  local gs = package.loaded.gitsigns
  vim.keymap.set("n", "<Leader>gj", gs.next_hunk)
  vim.keymap.set("n", "<Leader>gk", gs.prev_hunk)
  vim.keymap.set("n", "<Leader>gd", gs.diffthis)
end
```

| Tool | Trigger | Purpose |
|------|---------|---------|
| gitsigns | Always active | Line blame, hunk staging/nav |
| lazygit | `<Leader>gg` | Full Git TUI |
| diffview.nvim | `<Leader>gd` | Commit/file diff browser |
| telescope git pickers | `<Leader>f` variants | Git status/commits/branches |

### 8. File Management

| Tool | Trigger | Best For |
|------|---------|----------|
| **oil.nvim** | `-` in normal mode | Rename/move by editing paths, `:w` to apply |
| **neo-tree.nvim** | `<Leader>e` | Sidebar tree with git overlay |
| **lf** | `<Leader>tF` | Terminal TUI with previews |
| **yazi** | Terminal | Full-featured TUI (external) |

### 9. AI (codecompanion.nvim)

| Key | Action |
|-----|--------|
| `<Leader>aa` | Toggle chat panel |
| `<Leader>ap` | Action palette |
| `v` select → `<Leader>aa` | Send selection to chat |

Configured with Copilot adapter for both chat and inline.

### 10. Session Management

```lua
:SaveSession     -- save workspace (resession.nvim)
:RestoreSession  -- restore workspace
```

Persists buffers, layout, cursor positions across restarts.

### 11. Keymap Registration (which-key.nvim)

```lua
local wk = require("which-key")
wk.add({
  { "<Leader>f", group = "file" },
  { "<Leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
})
```

Every `<Leader>` mapping should have a `desc` for which-key discoverability.

### 12. Project Root Detection

Auto-detected from `.git`, `compile_commands.json`, `go.mod`, `package.json`. `:AstroRoot` to manually update cwd. `autochdir = true` switches automatically.

---

## Workflows

### Go Development

```
1. Open Go project     → nvim .
2. Find files          → <Leader>ff
3. Edit                → gopls: diagnostics, autocomplete, inlay hints
4. Format on save      → :w (gofumpt via gopls)
5. Go to def           → gd
6. See references      → gr
7. Browse docs         → :GoDoc (vertical split, telescope picker)
8. Run function test   → <Leader>tr (neotest-go)
9. Run all tests       → <Leader>tf
10. Debug test         → <F5> (delve via go.nvim DAP)
11. Step through       → <F10>/<F11>
12. Lint project       → :GolangciLint
13. Code actions       → <Leader>ca (gopls: add import, fill struct, etc.)
14. Rename symbol      → <Leader>rn
15. Git commit         → <Leader>gg (lazygit)
16. Review diff        → <Leader>gd (diffview)
```

**gopls features enabled**: unusedparams, shadow, nilness, unusedwrite, useany analyses; staticcheck; codelenses for generate/gc_details/run_govulncheck/tidy; inlay hints for types/params/fields.

### Python Development

```
1. Open Python project → nvim .
2. Edit                → basedpyright: diagnostics, type checking
3. Lint+format on save → :w (ruff: lint + organize imports + format)
4. Select venv         → :VenvSelect (auto-detects venv/.venv)
5. Go to def           → gd (basedpyright)
6. Run nearest test    → <Leader>tr (neotest-python, pytest)
7. Debug file          → <F5> (debugpy, auto-detects venv python)
8. Evaluate expr       → <Leader>de (dap-ui eval)
9. Code quality        → <Leader>xx (trouble diagnostics)
10. Rename             → <Leader>rn
```

### C/C++ Development

```
1. Open C/C++ project  → nvim .
2. LSP                 → clangd: diagnostics, autocomplete
3. Format on save      → :w (clang-format via clangd)
4. Build               → CMake integration (cmake-tools.nvim)
5. Debug               → <F5> → enter executable path (codelldb)
6. Step through        → <F10>/<F11>
7. Breakpoint          → <Leader>b
8. Memory analysis     → :HexToggle (binary files)
```

### Debugging (General)

```
1. Set breakpoint      → <Leader>b
2. Start debug         → <F5>
3. Step over           → <F10>
4. Step into           → <F11>
5. Step out            → <F12>
6. Inspect variables   → <Leader>de (evaluate expression)
7. Toggle DAP UI       → <Leader>dt (shows scopes, stacks, watches)
8. Re-run last session → <Leader>dr
9. Conditional bp      → <Leader>B
```

DAP UI shows: scopes (variables), stacks (call stack), watches (expressions), breakpoints list.

### Git Operations

```
1. See line blame      → gitsigns (live, sign column)
2. Stage hunk          → :Gitsigns stage_hunk (if mapped)
3. Next/prev hunk      → <Leader>gj / <Leader>gk
4. Open lazygit        → <Leader>gg (full Git TUI)
5. Stage files         → Space (in lazygit)
6. Commit              → c (in lazygit)
7. Push                → P (in lazygit)
8. Browse branch       → d (in lazygit: diff)
9. View commit diff    → <Leader>gd (diffview)
10. Search commits     → Telescope git_commits
11. Search branches    → Telescope git_branches
12. TODO/FIXME review  → <Leader>to (todo-comments.nvim)
```

### File Operations

```
Oil.nvim (directory as buffer):
  1. Press -            → open parent directory
  2. Navigate           → j/k, enter to open
  3. Rename             → edit the filename in the buffer, :w
  4. Move               → edit the path, :w
  5. Delete             → dd on a line, :w
  6. New file           → o on a directory line, type name, :w
  7. Preview            → <C-p>
  8. Hidden files       → g.
  9. Open in split      → <C-s> (vert), <C-h> (horiz)

Neo-tree (sidebar):
  1. Toggle sidebar     → <Leader>e
  2. Navigate           → j/k, enter
  3. Git status         → icons show modified/added/deleted
  4. Open in split      → <C-v>
  5. Filter             → f

lf (terminal TUI):
  1. Open lf            → <Leader>tF
  2. Navigate           → j/k, h/l (parent/enter), v (select)
  3. Preview            → auto (bat, chafa, ffprobe)
  4. Search             → f (fzf integration)
  5. Bulk rename        → :bulkrename
  6. Extract archives   → Enter on .tar.gz/.zip (auto-extract)
  7. Create archive     → :archive
  8. Close → back to nvim → directory is remembered, toggleterm opens there

Yazi (external TUI):
  - Invoke from shell   → yazi
  - Vi-style keymaps    → j/k, h/l, : for commands
  - Image previews      → via ueberzugpp
  - Git integration     → git plugin shows status
```

### Binary Analysis & API Testing

```
Hex view (hex.nvim):
  1. Open binary        → nvim binary_file
  2. Toggle hex view    → <Leader>H or :HexToggle
  3. Toggle ASCII       → :HexAscii
  4. Edit in hex mode   → modifications write back on save
  5. Dump hex           → :HexDump
  6. Assemble from hex  → :HexAssemble

REST client (rest.nvim):
  1. Create .http file  → touch request.http
  2. Write request:
     GET https://api.example.com/v1/users
     Authorization: Bearer {{token}}
  3. Send request       → :Rest run (cursor on request line)
  4. Set variable       → :Rest set token=abc123
  5. Open response      → :Rest open (in split)
  6. Environment vars   → {{var_name}} in request files

Log analysis (vim-logreview):
  1. Open log file      → nvim server.log
  2. Toggle review      → :Logreview
  3. Highlights         → timestamps, IPs, error levels, PIDs
  4. Use for            → nmap output, server logs, security tool output
```

### Writing & Research

```
1. Open markdown file   → nvim doc.md
2. Toggle inline render → :RenderMarkdown toggle (render-markdown.nvim)
3. Grammar check        → ltex-ls (auto: en-US + ru-RU dictionaries)
4. LanguageTool server  → http://lt.bme.local (configurable via $LANGUAGE_TOOLS)
5. Spell check          → built-in: en_us + ru_yo (:]s / [s to navigate, zg to add)
6. Live preview         → :MarkdownPreview (browser preview)
7. Stop preview         → :MarkdownPreviewStop
8. Zen mode             → :ZenMode (centered, 120-width, no UI)
9. Add custom words     → spells stored in spell/ directory
```

### Project Navigation

```
1. Find files           → <Leader>ff
2. Live grep            → <Leader>fg (requires ripgrep)
3. Switch buffers       → <Tab>/<S-Tab> or ]b/[b
4. Search buffers       → <Leader>fb
5. Search word          → <Leader>fw (word under cursor)
6. Search help          → <Leader>fh
7. Search keymaps       → :Telescope keymaps
8. Jump back/forward    → <C-o> / <C-i> (jump list)
9. Jump to change       → g; / g, (change list)
10. Trouble diagnostics → <Leader>xx (buffer), <Leader>xw (workspace)
11. TODO comments       → <Leader>to
12. Explore sessions    → :SaveSession / :RestoreSession
```

### Code Quality Pipeline

```
Write                     → LSP real-time diagnostics
Review diagnostics        → <Leader>xx (Trouble)
Navigate errors           → [d / ]d
Apply code action         → <Leader>ca
Rename symbol             → <Leader>rn
Review TODOs/FIXMEs       → <Leader>to
Format on save            → :w (conform / LSP)
Run tests                 → <Leader>tr
Debug failures            → <F5>
Git blame + review        → gitsigns + diffview
```

### Containerized Development

#### Dockerfile Reference

| File | Base | Packages | Use Case |
|------|------|----------|----------|
| `Dockerfile.apt` | `debian:trixie` | apt default | Full dev env with Neovim (Lazy install), non-root user |
| `Dockerfile.brew` | `debian:trixie` | apt default + Homebrew | Full dev env with Neovim + brew packages |
| `Dockerfile.dev-debian_trixie` | `debian:trixie` | Minimal (curl, wget, git) | Lightweight base for customization |
| `Dockerfile.dev-debian_bookworm` | `debian:bookworm` | Minimal (curl, wget, git) | Legacy Debian compatibility |

#### Build Args

All full Dockerfiles accept:

| Arg | Default | Description |
|-----|---------|-------------|
| `PK_BASE_IMAGE_NAME` | `debian` | Base image name |
| `PK_BASE_IMAGE_TAG` | `trixie` | Base image tag |
| `UID` | `1000` | Non-root user UID |
| `USER` | `user` | Non-root username |

#### Workflow

```bash
# 1. Build interactively (prompts which Dockerfile)
./scripts/build_docker-image.sh

# 2. Or build explicitly with custom args
docker build \
  --build-arg "USER=$USER" \
  --build-arg "UID=$UID" \
  -f Dockerfile.apt \
  -t my-pennykit:trixie \
  .

# 3. Run with current directory mounted as /workdir
./scripts/run_docker-container.sh

# 4. Inside container: full pennykit environment
nvim              # AstroNvim (pre-configured, plugins installed)
pennykit theme    # theme works inside container
pennykit extern   # install/update version-managed tools
```

#### Volume Mounts

`run_docker-container.sh` mounts `$(pwd)` to `/workdir` inside the container. The pennykit config lives at `~/.pennykit/` inside the container (not mounted), so each container gets a fresh install. To persist config across runs, add:

```bash
docker run -ti --rm \
  -v "$(pwd)":/workdir \
  -v pennykit-home:/home/user/.pennykit \  # persistent config volume
  -w /workdir \
  pennykit:trixie
```

#### Themes in Containers

Themes work identically inside containers:

```bash
pennykit theme gruvbox       # applies across all installed apps
pennykit theme --dry-run gruvbox  # preview without applying
```

Theme configs are copied into the image during build. To add custom themes, place `.conf` files in `configs/themes/` before building.

#### OS Detection Inside Container

Pennykit auto-detects the container environment:
- Detects Debian vs Ubuntu via `/etc/os-release`
- Skips Homebrew on Linux unless explicitly sourced (`brew.on_linux`)
- Skips cargo builds if `rustc` is unavailable
- Adjusts package installation to match the OS

### Theme Switching

```bash
pennykit theme               # show current + available themes
pennykit theme gruvbox       # apply across all 12+ apps
pennykit theme list          # list available themes
```

Applies to: WezTerm (Linux + macOS), Neovim (all 3 starters), bat, yazi, vivid (LS_COLORS), harlequin, lazygit, tmux, lf, Oh My Bash, Oh My Zsh.

### Config Switching

```bash
pennykit nvim            # interactive: astronvim_v6 / lazyvim / kickstart / disable
pennykit status          # dashboard: repo, branch, nvim config, theme, extern counts
```

Switching nvim config clears `~/.local/share/nvim`, `~/.local/state/nvim`, and `~/.cache/nvim`.

### Package Management

```bash
pennykit extern             # update default packages (fzf, golang, lazygit, nvim, yazi, ...)
pennykit extern admin       # admin packages (dive, godap, hadolint)
pennykit extern dev         # dev packages
pennykit extern pentest     # pentest packages
pennykit extern all         # everything
pennykit extern deactivate <pkg>  # skip a package
pennykit extern activate <pkg>    # re-enable
pennykit extern list-deactivated  # show skipped
pennykit update             # git pull --rebase self-update
```

---

## Shell Integration

### Aliases (pennykit_shell.alias)

| Alias | Expands to |
|-------|-----------|
| `v`/`vi`/`vim` | `nvim` |
| `vz`/`viz`/`vimz` | `nvim -c 'ZenMode'` |
| `gs` | `git status` |
| `gpl`/`gps` | `git pull`/`git push` |
| `gc` | `git commit` |
| `gundo` | `git reset --soft HEAD~1` |
| `ll`/`la`/`lla`/`lt` | `ls -la`, `ls -A`, etc. |
| `mc` | `midnight commander` |
| `vimdiff` | `nvim -d` |

### Functions (pennykit_shell.functions)

| Function | Usage |
|----------|-------|
| `note` | `note task` (edit task note), `note -d` (timesheet), `note -l` (fzf list) |
| `mkcd` | `mkcd dir` → mkdir + cd |
| `serve` | Python HTTP server on port 8080 |
| `bak`/`orig` | `bak file` → `file.bak`, `orig file` → revert |
| `penny-theme` | Theme switcher with `.bashrc` reload prompt |
| `Ctrl+F` | `fzf_rg_nvim`: rg search → fzf pick → nvim open |

### Environment (pennykit_shell.exports)

`EDITOR`/`VISUAL` = `nvim`, `HISTSIZE=10000`, `LS_COLORS` via vivid, `FZF_DEFAULT_COMMAND=rg`, `FZF_CTRL_T_OPTS` with bat preview.

---

## Quick Reference: All Major Keymaps

| Category | Key | Action |
|----------|-----|--------|
| **File** | `<Leader>ff` | Find files |
| | `<Leader>fg` | Live grep |
| | `<Leader>fb` | Buffers |
| | `-` | Oil.nvim (dir as buffer) |
| **LSP** | `gd` | Go to definition |
| | `gr` | References |
| | `gD` | Declaration |
| | `K` | Hover docs |
| | `<Leader>rn` | Rename |
| | `<Leader>ca` | Code action |
| | `<Leader>l` | LSP prefix menu |
| **Git** | `<Leader>gg` | Lazygit |
| | `<Leader>gj/k` | Hunk nav |
| | `<Leader>gd` | Diffview |
| **Debug** | `<F5>` | Continue |
| | `<F10>` | Step over |
| | `<F11>` | Step into |
| | `<F12>` | Step out |
| | `<Leader>b` | Breakpoint |
| | `<Leader>B` | Conditional breakpoint |
| | `<Leader>dt` | Toggle DAP UI |
| | `<Leader>de` | Evaluate |
| | `<Leader>dr` | Run last |
| **Test** | `<Leader>tr` | Run nearest |
| | `<Leader>tf` | Run file |
| | `<Leader>ts` | Toggle summary |
| | `<Leader>tS` | Stop |
| **Buffer** | `<Tab>` / `<S-Tab>` | Next / Prev buffer |
| | `]b` / `[b` | Next / Prev buffer |
| | `<Leader>bd` | Close (with picker) |
| **Terminal** | `<Leader>th` | Horizontal toggle |
| | `<Leader>tv` | Vertical toggle |
| | `<Leader>tl` | Lazygit terminal |
| | `<Esc><Esc>` | Exit terminal mode |
| **Diagnostics** | `<Leader>xx` | Trouble buffer |
| | `<Leader>xw` | Trouble workspace |
| | `<Leader>to` | TODO comments |
| **Window** | `<C-h/j/k/l>` | Pane/window nav (tmux-aware) |
| | `<M-Up/Down>` | Resize height ±2 |
| | `<M-Left/Right>` | Resize width ±2 |
| **AI** | `<Leader>aa` | Toggle chat |
| | `<Leader>ap` | Action palette |
| **Hex** | `<Leader>H` | Toggle hex view |
| | `:HexDump` | Hex dump |
| | `:HexAssemble` | Assemble from hex |
| **Markdown** | `:MarkdownPreview` | Live browser preview |
| | `:RenderMarkdown toggle` | Inline render toggle |
| **Zen** | `:ZenMode` | Focused writing |
| **Custom** | `:PKhello` | Hello command |
| **Which-key** | `<Leader>wK` | Interactive menu explorer |

This table includes framework-provided defaults (AstroNvim/LazyVim) plus custom overlays. To regenerate the **custom-only** keymap table from config files:

```bash
python3 "$PENNYKIT_HOME/scripts/gen_keymap_ref.py"
```

The script scans `lua/plugins/*.lua` across all starters for keymap definitions with `desc` fields.

---

## Cross-Starter Compatibility

Pennykit ships 3 Neovim starter configs in `nvim-starter/`. The primary is **AstroNvim v6**; LazyVim and kickstart are available via `pennykit nvim`.

### Shared Across All 3

| Category | Feature | Notes |
|----------|---------|-------|
| Plugin manager | `folke/lazy.nvim` | All use lazy.nvim |
| Theme mechanism | `_local_theme.lua` + colorscheme fallback | Identical `_local_theme.lua` returning `gruvbox-material` |
| Editorconfig | `vim.g.editorconfig = true` | |
| Leader key | `<Space>` | |
| Mason | mason.nvim / mason-tool-installer.nvim | All use mason ecosystem |
| LSP | nvim-lspconfig or AstroLSP | All configure LSP |
| Git signs | gitsigns.nvim | Kickstart: optional module |
| Which-key | `folke/which-key.nvim` | Popup keybinding helper |

### AstroNvim v6 Only

| Feature | Notes |
|---------|-------|
| **AstroNvim framework** | `astrocore`, `astrolsp`, `astroui` |
| **6 conditional themes** | catppuccin, dracula, gruvbox-material, nord, solarized, tokyonight |
| **15 language packs** | via AstroCommunity (ansible, bash, cmake, cpp, docker, go, json, lua, markdown, python, toml, yaml, ...) |
| **Test runner** | neotest (Python/Go) |
| **Markdown** | preview + inline render + log review |
| **Hex viewer** | `hex.nvim` |
| **REST client** | `rest.nvim` |
| **Oil.nvim** | file-as-buffer (`-`) |
| **Lf / tmux-navigator** | file manager + tmux pane nav |
| **Go doc browser** | `godoc.nvim` |
| **AI chat** | `codecompanion.nvim` |
| **Trouble + Diffview** | via AstroCommunity |
| **DAP** | codelldb + debugpy with venv auto-detect |
| **20+ mason tools** | auto-installed (bash-language-server, beautysh, cpptools, codelldb, gopls, gofumpt, golangci-lint, delve, ltex-ls, docker LSPs, ...) |
| **Spell** | enabled (en+ru), custom word lists |
| **Custom commands** | `:PKhello` |

### LazyVim Only

| Feature | Notes |
|---------|-------|
| **LazyVim framework** | `LazyVim/LazyVim` with full plugin ecosystem |
| **Cyrillic.nvim** | Keyboard layout helper |

### Kickstart Only

| Feature | Notes |
|---------|-------|
| **Self-contained init.lua** | ~1024 lines, plugins defined inline |
| **blink.cmp** | Completion engine (instead of nvim-cmp) |
| **mini.nvim** | mini.ai, mini.surround, mini.statusline |
| **Nerd Font gating** | `vim.g.have_nerd_font` controls icons |
| **guess-indent.nvim** | Auto-detect indentation |
| **6 modular plugins** | debug, gitsigns-keymaps, autopairs, indent-blankline, lint, neo-tree (all disabled by default) |

### Switching Configs

```bash
pennykit nvim              # interactive: astronvim_v6 / lazyvim / kickstart / disable
```

Switching clears `~/.local/share/nvim`, `~/.local/state/nvim`, and `~/.cache/nvim`. `:Lazy install` is required after switch.

---

## Performance Checklist

- [ ] `:Lazy profile` — target <50ms startup
- [ ] Prefer `event`/`cmd`/`ft`/`keys` triggers; avoid `lazy = false` except for core
- [ ] Pin versions via `lazy-lock.json` after every `:Lazy update`
- [ ] Run `:checkhealth` after config changes
- [ ] Treesitter parsers: `ensure_installed` (22 parsers configured)
- [ ] Mason tools: `ensure_installed` (20 tools auto-installed)

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| LSP not starting | `:LspInfo` or `:checkhealth vim.lsp` |
| Icons missing | Install a Nerd Font |
| Plugins not loading | `:Lazy health` |
| Slow startup | `:Lazy profile` |
| Treesitter errors | `:TSUpdate` |
| Keybinding conflicts | `:verbose map <key>` |
| Debugger not working | `:DapInstall <adapter>` first |
| Markdown preview fails | `:Lazy build markdown-preview.nvim` |
| Hex view not showing | File too large (hex.nvim has limits) |
