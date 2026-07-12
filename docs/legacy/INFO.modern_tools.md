# Modern Linux Programs & Utilities

---

## File & Directory Navigation

**eza** *(replaces: ls)*
Modern `ls` with color, icons, Git status, and tree view built in.

**lsd** *(replaces: ls)*
LSDeluxe — another `ls` rewrite with Nerd Font icons and rich color themes.

**zoxide** *(replaces: cd / autojump / z)*
Smarter `cd` that learns your most-used directories and jumps with partial names.

**broot** *(replaces: tree / find)*
Interactive tree navigator with fuzzy search and file launch from inside the view.

**yazi** *(replaces: ranger / nnn / lf)*
Blazing-fast terminal file manager with image preview, async I/O, and plugin system.

---

## Search & Filtering

**rg** *(replaces: grep)*
Ripgrep — extremely fast recursive text search, respects `.gitignore` by default.

**fd** *(replaces: find)*
Intuitive `find` replacement with simpler syntax, color output, and parallel execution.

**fzf** *(replaces: dmenu / grep pipelines)*
General-purpose fuzzy finder for files, history, processes — integrates with any shell.

**ag** *(replaces: ack / grep)*
The Silver Searcher — fast code search tool, predecessor to ripgrep, still widely used.

---

## Text Processing & Viewing

**bat** *(replaces: cat / less)*
A `cat` clone with syntax highlighting, line numbers, Git diff markers, and paging.

**delta** *(replaces: diff / git diff)*
Syntax-highlighting pager for `git diff` output with side-by-side and word-level diffs.

**jq** *(replaces: python -m json.tool)*
Lightweight JSON processor and query language — slice, filter, map JSON from the CLI.

**fx** *(replaces: jq interactive)*
Interactive terminal JSON viewer with a keyboard-driven collapsible tree.

**mlr** *(replaces: awk)*
Miller — like `awk` for CSV/TSV/JSON; named-field processing of tabular data.

---

## System Monitoring & Diagnostics

**btop** *(replaces: top / htop)*
Beautiful resource monitor — CPU, memory, disk, network, and processes in one TUI.

**procs** *(replaces: ps)*
Modern `ps` replacement with color, tree view, and human-readable columns.

**dust** *(replaces: du / ncdu)*
Intuitive disk usage viewer — a tree-chart reimagining of `du`.

**duf** *(replaces: df)*
Disk Usage/Free — colorful, grouped table of mounted filesystems.

**hyperfine** *(replaces: time)*
Command-line benchmarking tool with warmup runs, statistical analysis, and export.

---

## Networking & HTTP

**httpie** *(replaces: curl)*
Human-friendly HTTP client with intuitive syntax, colored output, and JSON support.

**curlie** *(replaces: curl)*
Power of `curl` with httpie-style colored output — a thin, compatible wrapper.

**dog** *(replaces: dig / nslookup)*
Colorful DNS lookup tool with support for DNS-over-TLS and DNS-over-HTTPS.

**bandwhich** *(replaces: nethogs / iftop)*
Displays network utilization per process, connection, and remote IP in real time.

---

## Development Tooling

**lazygit** *(replaces: git CLI / tig)*
Full-featured terminal UI for Git — stage hunks, rebase interactively, resolve conflicts.

**gh** *(replaces: browser-based GitHub)*
Official GitHub CLI — create PRs, manage issues, run Actions, clone repos from the terminal.

**just** *(replaces: make)*
A command runner / task tool — like `make` but focused purely on running project commands.

**tokei** *(replaces: cloc / sloccount)*
Counts lines of code, comments, and blanks across a codebase — fast and accurate.

**watchexec** *(replaces: inotifywait / entr)*
Runs a command when files change — great for auto-rebuild, auto-test, and live reload.

---

## Shell & Terminal Experience

**starship** *(replaces: oh-my-zsh / powerlevel10k)*
Cross-shell prompt written in Rust — shows Git, language versions, exit codes, and more.

**nushell** *(replaces: bash / zsh)*
A new shell where everything is structured data — pipelines return tables, not text.

**atuin** *(replaces: Ctrl+R history)*
Replaces shell history with a searchable SQLite database; optional encrypted sync across machines.

**tmux** *(replaces: screen)*
Terminal multiplexer — split panes, persist sessions, and detach/reattach over SSH.

**zellij** *(replaces: tmux)*
Modern terminal workspace with a built-in status bar, layouts, and plugin system.

