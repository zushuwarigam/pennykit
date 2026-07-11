# Neovim Development Guide

Built on AstroNvim v6 — leader key: `<Space>`

## Project Structure

```
~/.config/nvim/
├── init.lua                  # Entry point (bootstraps lazy.nvim)
├── lua/
│   ├── lazy_setup.lua        # lazy.nvim config + AstroNvim import
│   ├── community.lua         # AstroCommunity packs (lang support)
│   ├── custom_commands.lua   # User-defined commands
│   ├── polish.lua            # Late-stage setup hook
│   └── plugins/              # Per-plugin config
│       ├── astrocore.lua     # Core: options, keymaps, mason ensures
│       ├── astrolsp.lua      # LSP: gopls, clangd, ruff, ltex
│       ├── astroui.lua       # UI: colorscheme, icons
│       ├── dap.lua           # Debug: Python (venv), C/C++ (codelldb)
│       ├── go.lua            # Go: go.nvim (tests, debug, inlay hints)
│       ├── codecompanion.lua # AI chat assistant
│       ├── mason.lua         # Mason auto-installer (LSPs, formatters)
│       ├── treesitter.lua    # Syntax highlighting parsers
│       ├── tmux-navigation.lua
│       ├── lf.lua            # File manager
│       ├── toggleterm-manager.lua
│       ├── hex.lua            # Hex viewer (binary analysis)
│       ├── rest.lua           # REST API client
│       ├── logreview.lua      # Log file highlighting
│       ├── glow.lua           # Inline markdown rendering via render-markdown.nvim
│       ├── oil.lua            # File system as buffer
│       ├── neotest.lua        # Interactive test runner
│       ├── markdown-preview.lua # Live markdown preview
│       └── godoc.lua         # Go documentation browser
├── spell/                    # Custom spelling dictionaries (en, ru)
└── lazy-lock.json            # Pinned plugin versions
```

## Key Mappings

### General Navigation
| Key | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Next/Previous buffer |
| `]b` / `[b` | Next/Previous buffer |
| `<Leader>bd` | Close buffer (with picker) |

### Window Management
| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate tmux panes / vim windows |
| `<M-Up/Down>` | Resize window height ±2 |
| `<M-Left/Right>` | Resize window width ±2 |

### File & Search
| Key | Action |
|-----|--------|
| `<Leader>tF` | Open lf file manager |
| `-` | Open oil.nvim (directory as buffer) |
| `<Leader>ff` | Find files |
| `<Leader>fg` | Live grep (requires ripgrep) |
| `<Leader>fb` | Buffer list |
| `<Leader>fw` | Search word under cursor |

### LSP (Language Server)
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `<Leader>rn` | Rename symbol |
| `<Leader>ca` | Code action |
| `<Leader>l` | LSP-related commands prefix |

### AI CodeCompanion
| Key | Action |
|-----|--------|
| `<Leader>aa` | Toggle AI chat panel |
| `<Leader>ap` | AI action palette |
| `v` → `<Leader>aa` | Send selection to chat |

### Debugging (DAP)
| Key | Action |
|-----|--------|
| `<F5>` | Continue / Start |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<Leader>b` | Toggle breakpoint |
| `<Leader>B` | Conditional breakpoint |
| `<Leader>dt` | Toggle DAP UI panel |
| `<Leader>de` | Evaluate expression |
| `<Leader>dr` | Re-run last debug session |

### Git
| Key | Action |
|-----|--------|
| `<Leader>gg` | Lazygit (if installed) |
| `<Leader>gj` / `<Leader>gk` | Next/Previous git hunk |
| `<Leader>gd` | Diffview (git diff browser) |

### Terminal
| Key | Action |
|-----|--------|
| `<Leader>tl` | Lazygit terminal |
| `<Leader>th` | Horizontal terminal toggle |
| `<Leader>tv` | Vertical terminal toggle |
| `<Esc><Esc>` | Exit terminal mode |

### Diagnostics & Quality
| Key | Action |
|-----|--------|
| `<Leader>xx` | Trouble diagnostics list |
| `<Leader>xw` | Workspace diagnostics |
| `<Leader>to` | TODO/FIXME comments list |

### Hex & Binary
| Key | Action |
|-----|--------|
| `:HexToggle` / `<Leader>H` | Toggle hex view on current buffer |
| `:HexDump` | Dump buffer as hex |
| `:HexAssemble` | Assemble hex back to binary |

### REST API
| Key | Action |
|-----|--------|
| `:Rest run` | Execute HTTP request under cursor |
| `:Rest open` | Open response in split |
| `:Rest set` `variable=value` | Set environment variable |

### Markdown
| Key | Action |
|-----|--------|
| `:MarkdownPreview` | Open live browser preview |
| `:MarkdownPreviewStop` | Stop preview |
| `:RenderMarkdown toggle` | Toggle inline markdown rendering |

### Testing (neotest)
| Key | Action |
|-----|--------|
| `<Leader>tr` | Run nearest test |
| `<Leader>tf` | Run test file |
| `<Leader>ts` | Toggle test output summary |
| `<Leader>tS` | Stop running tests |

### Log Analysis
| Key | Action |
|-----|--------|
| `:Logreview` | Toggle log review highlighting |

**All mappings can be explored interactively with `<Leader>wK` (which-key).**

## Language-Specific Features

### C / C++
- **LSP**: `clangd` — diagnostics, autocomplete, code actions
- **Format**: `clang-format` on save (auto-enabled for `.c`/`.cpp`)
- **Debug**: codelldb via `<F5>` (prompts for executable path)
- **Build**: CMake integration via `cmake-tools.nvim`
- **Parsers**: treesitter for `c`, `cpp`, `objc`, `cuda`, `proto`
- **Install debugger**: `:DapInstall cpptools`

### Go
- **LSP**: `gopls` — full analyses suite (unused params, shadow, nilness, useany)
- **Format**: `gofumpt` on save
- **Lint**: `golangci-lint` via `:GolangciLint`
- **Test**: `:GoTest` / `:GoTestFunc` — output in floating terminal
- **Debug**: `delve` via `<F5>` — uses go.nvim DAP integration
- **Docs**: `:GoDoc` — browse Go documentation in vertical split
- **Tools**: `gomodifytags`, `impl`, `iferr`, `gotests`

### Python
- **LSP**: `basedpyright` — type checking, autocomplete, diagnostics
- **Lint+Format**: `ruff` — ultra-fast Python linting and formatting
- **Debug**: `debugpy` via `<F5>` — auto-detects `venv`/`.venv` python
- **Test**: `<Leader>tr` — run nearest test via neotest
- **Virtual envs**: `:VenvSelect` to choose interpreter
- **Install LSP**: `:LspInstall basedpyright`, `:LspInstall ruff`

### Bash
- **LSP**: `bashls` — autocomplete, syntax errors
- **Lint**: `shellcheck` — static analysis
- **Format**: `shfmt` (via beautysh in mason)
- **Debugger**: bash debugger included in pack

### Docker
- **LSP**: `docker-language-server`, `dockerfile-language-server`
- **Highlight**: Dockerfile + docker-compose syntax via treesitter

### Markdown / LaTeX
- **Grammar**: `ltex-ls` language checker (en+ru dictionaries)
- **Spell**: built-in spell check enabled (`en_us`, `ru_yo`)
- **Server**: connects to LanguageTool at `http://lt.bme.local` (configurable via `$LANGUAGE_TOOLS`)

## Security Research Tools

### Hex Viewer (hex.nvim)
- **Toggle hex view**: `:Hex` — toggle between hex dump and normal mode
- **Ascii mode**: `:HexAscii` — show ASCII representation alongside hex
- Use for: binary analysis, patch diffing, file carving, reverse engineering
- The buffer is editable in hex mode — modifications write back to the original file

### REST Client (rest.nvim)
- **Send request**: `:Rest run` — execute HTTP request at cursor position
- **Request files**: create `.http` or `.rest` files with HTTP method syntax
- **Environment variables**: define `{{variable}}` in request files, resolve via `:Rest set`
- Use for: API testing during web app research, endpoint enumeration
- Example request file:
  ```http
  GET https://api.target.com/v1/users
  Authorization: Bearer {{token}}
  ```
- Response opens in a scratch buffer with syntax highlighting

### Log Analysis (vim-logreview)
- **Review log**: `:Logreview` — toggle log review mode on current buffer
- **Filetype**: activates `logreview` highlighting — timestamps, IPs, error levels, PID highlighted
- Use for: parsing nmap/masscan output, server logs, security tool output, error triage

### Testing (neotest)
- **Run nearest test**: `<Leader>tr` — run test under cursor
- **Run test file**: `<Leader>tf` — run all tests in current file
- **Toggle summary**: `<Leader>ts` — show/hide test output summary
- **Stop**: `<Leader>tS` — stop running tests
- Supports Python (pytest) and Go (go test) outputs in floating terminal

## Colorschemes

| Theme | Switch command |
|-------|---------------|
| gruvbox-material (default) | `:colorscheme gruvbox-material` |
| catppuccin (mocha) | `:colorscheme catppuccin` |
| tokyonight | `:colorscheme tokyonight` |
| astrotheme | `:colorscheme astrotheme` |

## Mason — Tool Management

Tools auto-installed by `mason-tool-installer`:

| Category | Tools |
|----------|-------|
| **C/C++** | cpptools, codelldb |
| **Go** | gopls, gofumpt, golangci-lint, delve, gomodifytags, impl |
| **Python** | basedpyright, ruff, debugpy |
| **Bash** | bash-language-server, beautysh |
| **Docker** | docker-language-server, dockerfile-language-server |
| **General** | lua-language-server, stylua, tree-sitter-cli |
| **Grammar** | ltex-ls, ltex-ls-plus |

- `:Mason` — browse/install/manage tools
- `:LspInstall <server>` — install a specific LSP
- `:DapInstall <adapter>` — install a debug adapter

## Package Management

| Command | Action |
|---------|--------|
| `:Lazy` | Open plugin manager |
| `:Lazy update` | Update all plugins |
| `:Lazy sync` | Sync and clean plugins |
| `:Lazy profile` | Profile startup time |
| `:AstroUpdate` | Update plugins + Mason packages |
| `:AstroVersion` | Show AstroNvim version |

## PennyKit Plugin Manager

Interactive plugin management with Telescope UI. Auto-syncs on open. Core AstroNvim plugins are excluded.

| Command | Action |
|---------|--------|
| `:PKPlugins` | Open Telescope picker (auto-syncs first) |
| `:PKPluginAdd` | Add a new user plugin |
| `:PKPluginSync` | Sync registry with `lua/plugins/` directory |

### Key Mappings

| Key | Action |
|-----|--------|
| `<Leader>pp` | Open PennyKit plugin picker |
| `<Leader>pa` | Add plugin |
| `<Leader>ps` | Sync plugins |

### Telescope Keymaps (in picker)

| Key | Action |
|-----|--------|
| `<Tab>` | Toggle current plugin (moves to next) |
| `<C-e>` | Enable all plugins |
| `<C-d>` | Disable all plugins |
| `<CR>` | Close picker |
| `<Esc>` | Close picker |
| `<C-h>` | Show help |

### How it works

1. **Opening picker**: Run `:PKPlugins` or `<Leader>pp`
   - Auto-syncs registry with `lua/plugins/` directory
   - Filters out core AstroNvim plugins
   - Shows only user-configurable plugins

2. **Toggling plugins**: Press `<Space>` to toggle enabled/disabled
   - Updates registry immediately
   - Changes take effect after restart or `:Lazy sync`

3. **Adding a plugin**: Enter `user/repo` or full GitHub URL
   - Creates `lua/plugins/<name>.lua` with the plugin spec
   - Adds to registry
   - Run `:Lazy sync` to install

### Plugin Guard Clause

Each plugin file uses this pattern:
```lua
local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("plugin-name") then return { enabled = false } end
```

This tells lazy.nvim to not load the plugin when disabled.

### Registry location

`~/.config/nvim/lua/pennykit/plugin_registry.json`

### Core Plugins (excluded from picker)

These are managed by AstroNvim, not PennyKit:
- astrocore, astrolsp, astroui, astrotheme
- telescope, which-key, mason, neo-tree
- treesitter, nvim-cmp, gitsigns, bufferline
- All other AstroNvim/AstroCommunity plugins

### Customizing plugins

Edit plugin files directly in `lua/plugins/` to add:
- `opts = {}` for plugin options
- `dependencies = {}` for dependencies
- `event = "..."` for lazy-loading
- `cmd = "..."` for command-based loading
- `ft = "..."` for filetype-based loading

### System packages

External tools (vivid, fzf, lazygit, etc.) are managed by PennyKit, not the nvim plugin manager:
- Install: `add_vivid` or run `./install`
- Config: `packages/extern.packages`

## Tips & Tricks

### First-time setup
1. Install a Nerd Font (https://www.nerdfonts.com)
2. Run `:Lazy sync` to install all plugins
3. Run `:Mason` to check LSP/debugger installation status
4. Run `:checkhealth` to verify everything works

### Navigation Superpowers
- `Ctrl-o` / `Ctrl-i` — jump back/forward through cursor history (jump list)
- `g;` / `g,` — jump to previous/next change in the file (change list)
- `gg` / `G` — go to top/bottom of file
- `%` — jump between matching bracket/brace
- `*` / `#` — search for word under cursor forward/backward
- `gf` — go to file under cursor (opens path in buffer)
- `gD` — go to declaration (LSP-aware)
- `gd` — go to definition (LSP-aware)
- Use `:jumps` to see your jump history
- Use `:changes` to see your change history

### Editing Power Moves
- `.` — repeat last change (single most powerful vim command)
- `*` then `n`/`N` to jump, then `.` to repeat — super fast find-and-replace
- `ciw` — change inner word (delete word and enter insert mode)
- `ci(` / `ci[` / `ci"` — change inside brackets/quotes
- `da(` / `da[` / `da"` — delete around brackets/quotes (includes delimiters)
- `g~~` — toggle case of current line
- `gUiw` — UPPERCASE current word
- `guiw` — lowercase current word
- `>>` / `<<` — indent/unindent current line
- `>G` — indent from cursor to end of file

### Multi-cursor & Block Editing
- `Ctrl-v` — enter visual block mode
- Select block, then `I` to insert at start, `A` to append at end
- Select block, then `d` to delete, `c` to change, `r` to replace
- Select block, then `~` to toggle case
- `g Ctrl-g` — show cursor position and byte/word/line count

### Macros
- `qa` — start recording macro into register `a`
- `q` — stop recording
- `@a` — play macro from register `a`
- `@@` — replay last macro
- `:normal @a` — run macro on all selected lines
- `:3,5norm @a` — run macro on lines 3-5

### Registers (clipboard)
- `"0p` — paste last yanked text (not deleted)
- `"+y` — yank to system clipboard
- `"+p` — paste from system clipboard
- `"*y` — yank to primary selection (X11 middle-click)
- `:reg` — view all register contents
- `"_d` — delete to black hole (no clipboard, like cutting without saving)

### Marks
- `mm` — set mark `m` at cursor position
- `'m` — jump to line of mark `m`
- `` `m `` — jump to exact position of mark `m`
- `'.` — jump to last edited line
- `''` — jump back to previous position
- `:marks` — list all marks
- Marks `a-z` are file-local, `A-Z` are global (across files)

### Sessions (resession.nvim)
- Session management is handled by `resession.nvim`:
  - `:SaveSession` / `:RestoreSession` — save/restore your workspace
  - Sessions remember open buffers, window layout, and cursor positions
  - Ideal for switching between projects without losing context

### Oil.nvim — Directory as Buffer
- Press `-` to open parent directory as a buffer
- Navigate and edit the file tree like a text file
- Rename/move/copy files by editing paths directly
- `:w` to apply changes, `:q` to discard
- `gf` on a filename to open that file
- `<C-v>` / `<C-s>` / `<C-t>` to open in vertical split / horizontal / tab

### Code Quality Workflow
1. Write code — LSP provides real-time diagnostics
2. `<Leader>xx` — open Trouble diagnostics list for current buffer
3. `<Leader>xw` — workspace diagnostics (all files)
4. Navigate errors with `[d` / `]d` (LSP), `[e` / `]e` (handled by AstroNvim)
5. `<Leader>ca` — apply quickfix/code action from LSP
6. `<Leader>rn` — rename symbol across project
7. `<Leader>to` — see TODO/FIXME/HACK comments

### Quickfix & Location List
- `:copen` — open quickfix list (search results, compiler output)
- `:lopen` — open location list (buffer-local diagnostics)
- `:cnext` / `:cprev` — navigate quickfix items
- `:lnext` / `:lprev` — navigate location items
- Quickfix is populated by `:grep`, `:make`, `:vimgrep`, and LSP code actions

### Undo Tree
- `u` / `Ctrl-r` — undo/redo
- `g-` / `g+` — go back/forward in undo history
- `:undolist` — list all undo branches
- Neovim has persistent undo — history survives restarts (file `.nvim/undo//`)

### Folding
- `za` — toggle fold under cursor
- `zR` — open all folds
- `zM` — close all folds
- `zc` / `zo` — close/open one fold
- `zd` — delete fold under cursor
- Treesitter-based folding is enabled (`za` works on code blocks)

### Project Root & Working Directory
- Project root is auto-detected (`.git`, `compile_commands.json`, `package.json`)
- `:AstroRoot` — manually update working directory to project root
- `:AstroRootInfo` — show detected project roots
- Working directory changes automatically when switching projects (`autochdir = true`)

### Spell Check
- `]s` / `[s` — jump to next/previous misspelled word
- `zg` — add word to dictionary (uses `spell/` directory)
- `z=` — suggest corrections
- Spell check is enabled for all filetypes (`:set spell`)
- Supports English and Russian (`ru_yo`)
- LanguageTool grammar checking for Markdown/LaTeX via `ltex-ls`

### Writing & Research
- **Zen mode**: `:ZenMode` — focused writing (centered, 120-width, no UI clutter)
- **Markdown Preview**: `:MarkdownPreview` — live browser preview for report writing
- **Markdown Render**: `:RenderMarkdown toggle` — toggle inline markdown rendering via render-markdown.nvim
- **LanguageTool** grammar check for Markdown/LaTeX via `ltex-ls`
- Custom dictionaries in `spell/` — add domain-specific terminology
- `:PKhello` — custom command (defined in `lua/custom_commands.lua`)

### Per-Project Settings
- Place `.luarc.json` in project root for Lua LSP project settings
- Place `.editorconfig` in project root for consistent formatting across editors
- Use `:e` with `exrc` option for project-local vim settings (see `:h exrc`)

### Performance Profile
- `:Lazy profile` — see which plugins slow down startup
- `:Lazy` then press `p` — profile results sorted by load time
- Target is <50ms startup. If slow: check for missing lazy-loading `event`/`cmd`/`ft` on plugins

### Discoverability
- `<Leader>wK` — which-key menu explorer (press keys to drill down)
- `:Telescope keymaps` — search all available keymaps by description/key
- `:cheat` — open AstroNvim cheat sheet (if installed)
- `:help` — Neovim built-in help (⌘ + `K` on a keyword)

### Troubleshooting
| Issue | Check |
|-------|-------|
| LSP not starting | `:LspInfo` or `:checkhealth vim.lsp` |
| Icons missing | Install a Nerd Font |
| Plugins not loading | `:Lazy health` |
| Slow startup | `:Lazy profile` |
| Treesitter errors | `:TSUpdate` |
| Keybinding conflicts | `:verbose map <key>` |
| Debugger not working | `:DapInstall` — install the adapter first |
| Markdown preview not working | `:Lazy build markdown-preview.nvim` — build the preview binary |
| Hex view not showing | Ensure file is not too large (hex.nvim has size limits) |

## File layout summary

```
init.lua → lazy_setup.lua
         → community.lua     (language packs)
         → plugins/*.lua     (per-plugin config)
         → polish.lua        (final overrides)
```

### Plugin directory (`lua/plugins/`)

Each plugin has its own file for easy management with PennyKit.

#### Core AstroNvim (managed by AstroNvim)
| File | Purpose |
|------|---------|
| `astrocore.lua` | Core options, keymaps, diagnostics |
| `astrocore_rooter.lua` | Project root detection |
| `astrolsp.lua` | LSP servers (gopls, clangd, ruff, ltex) |
| `astroui.lua` | UI, colorscheme, icons |
| `mason.lua` | Auto-installer for LSPs, formatters, debuggers |
| `treesitter.lua` | Syntax highlighting parsers |

#### User Plugins (managed by PennyKit)
| File | Purpose |
|------|---------|
| `go.lua` | Go tooling (go.nvim) |
| `dap.lua` | Debug adapters (Python, C/C++, Go) |
| `neotest.lua` | Interactive test runner |
| `rest.lua` | REST API client |
| `codecompanion.lua` | AI chat assistant |
| `hex.lua` | Hex viewer for binary analysis |
| `logreview.lua` | Log file highlighting |
| `glow.lua` | Inline markdown rendering |
| `oil.lua` | File system as buffer navigation |
| `lf.lua` | lf file manager |
| `godoc.lua` | Go documentation browser |
| `markdown-preview.lua` | Live markdown browser preview |
| `tmux-navigation.lua` | `<C-h/j/k/l>` tmux pane navigation |
| `toggleterm-manager.lua` | Terminal manager |
| `none-ls.lua` | null-ls formatter/linter sources |
| `zenmod.lua` | Zen mode (focused writing) |
| `languagetool.lua` | LanguageTool grammar checker |
| `luasnip.lua` | LuaSnip custom configuration |
| `autopairs.lua` | Autopairs custom configuration |
| `lsp_signature.lua` | LSP signature help |
| `snacks.lua` | Snacks.nvim (dashboard, notifications) |
| `presence.lua` | Discord Rich Presence |
| `user.lua` | User plugin overrides (disabled) |

#### Colorschemes
| File | Purpose |
|------|---------|
| `gruvbox-material.lua` | Default gruvbox-material theme |
| `catppuccin.lua` | Catppuccin theme config |
| `tokyonight.lua` | Tokyo Night theme config |
| `nord.lua` | Nord theme config |
| `dracula.lua` | Dracula theme config |
| `solarized.lua` | Solarized theme config |

Happy coding!
