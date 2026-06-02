#!/usr/bin/env python3
"""
Extract keymap references from Neovim plugin config files.

Scans lua/plugins/*.lua files across all starters for keymap definitions
with 'desc' fields and generates a markdown reference table.

Usage: PENNYKIT_HOME=~/.pennykit python3 scripts/gen_keymap_ref.py
"""

import re
import os
import sys
from collections import defaultdict

PENNYKIT_HOME = os.environ.get("PENNYKIT_HOME") or os.path.expanduser("~/.pennykit")

STARTER_DIRS = {
    "astronvim": f"{PENNYKIT_HOME}/nvim-starter/astronvim_v6/lua/plugins",
    "lazyvim": f"{PENNYKIT_HOME}/nvim-starter/lazyvim/lua/plugins",
    "kickstart": f"{PENNYKIT_HOME}/nvim-starter/kickstart",
}

CATEGORY_KEYWORDS = {
    "Search": ["telescope", "fzf-lua", "snacks.picker", "search", "grep", "find"],
    "File": ["oil", "neo-tree", "lf ", "file", "explorer"],
    "LSP": ["lsp", "definition", "references", "rename", "declaration", "hover", "code action"],
    "Git": ["gitsigns", "lazygit", "diffview", "hunk", "blame"],
    "Debug": ["dap", "debug"],
    "Test": ["neotest", "test"],
    "Diagnostics": ["trouble", "diagnostic"],
    "Window/Buffer": ["buffer", "window", "tmux", "resize", "focus", "split"],
    "Terminal": ["toggleterm", "terminal"],
    "AI": ["codecompanion", "chat", "ai"],
    "Hex": ["hex"],
    "Markdown": ["markdown", "glow"],
    "Zen": ["zen"],
    "Writing": ["languagetool"],
    "Format": ["conform", "format"],
}


def find_lua_files(root):
    if os.path.isfile(root):
        return [root]
    files = []
    for dirpath, _, names in os.walk(root):
        for n in names:
            if n.endswith(".lua"):
                files.append(os.path.join(dirpath, n))
    return sorted(files)


def strip_line_comments(text):
    return "\n".join(
        line for line in text.split("\n")
        if not line.strip().startswith("--")
    )


def find_matching_brace(s, start):
    """Find closing brace for brace at position start in string s."""
    if s[start] != "{":
        return -1
    depth = 0
    i = start
    in_str = False
    str_char = None
    while i < len(s):
        ch = s[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == str_char:
                in_str = False
        else:
            if ch in ("'", '"'):
                in_str = True
                str_char = ch
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1


def extract_table_strings(text):
    """Find all string literals (single/double quoted) in text."""
    strings = []
    for m in re.finditer(r"""["']([^"']+)["']""", text):
        strings.append(m.group(1))
    return strings


def categorize(desc, fname):
    d = desc.lower()
    f = fname.lower()
    for cat, keywords in CATEGORY_KEYWORDS.items():
        for kw in keywords:
            if kw in d or kw in f:
                return cat
    return "Other"


def extract_keymaps(filepath):
    """Extract keymaps from a Lua config file.

    Handles three patterns:
    A: vim.keymap.set(mode, lhs, rhs, { desc = "..." })
    B: ["<lhs>"] = { ... desc = "..." }   (AstroNvim mappings table)
    C: { "<lhs>", ..., desc = "..." }      (lazy.nvim keys table)
    """
    with open(filepath) as f:
        raw = f.read()

    content = strip_line_comments(raw)
    keymaps = []
    fname = os.path.basename(filepath)

    # --- Pattern A: vim.keymap.set calls ---
    # Match: vim.keymap.set(mode, lhs, ... opts with desc)
    # Try both single and double quotes
    for m in re.finditer(
        r"""vim\.keymap\.set\(\s*['"]([nixvtsco]{1,2})['"]\s*,\s*['"]([^'"]+)['"]\s*,""",
        content,
    ):
        mode, lhs = m.group(1), m.group(2)
        # Find the matching closing paren
        close_paren = content.find(")", m.end())
        if close_paren == -1:
            continue
        opts_block = content[m.end() : close_paren]
        # Find desc in the opts
        dm = re.search(r"""desc\s*=\s*['"]([^'"]+)['"]""", opts_block)
        if dm:
            desc = dm.group(1)
            keymaps.append((mode, lhs, desc, fname))

    # --- Pattern B: AstroNvim mappings table entries ---
    # ["<lhs>"] = { ... desc = "..." }
    for m in re.finditer(
        r"""\[\s*['"]([^'"]+)['"]\s*\]\s*=\s*\{""",
        content,
    ):
        lhs = m.group(1)
        # Skip which-key group menus (name only, no function/cmd)
        brace_end = find_matching_brace(content, m.end() - 1)
        if brace_end == -1:
            continue
        block = content[m.end() - 1 : brace_end + 1]
        if re.search(r"""name\s*=\s*['"]""", block) and not re.search(
            r"""['"]<(?:[Cc]md|[Cc]r)""", block
        ) and not re.search(r"function", block):
            continue
        # Detect mode from context
        context_before = content[: m.start()]
        mode = "n"
        modes_found = re.findall(r"^\s*(\w)\s*=\s*\{", context_before, re.MULTILINE)
        if modes_found:
            mode = modes_found[-1]
        dm = re.search(r"""desc\s*=\s*['"]([^'"]+)['"]""", block)
        if dm:
            desc = dm.group(1)
            keymaps.append((mode, lhs, desc, fname))

    # --- Pattern C: lazy.nvim keys table entries ---
    # { "<lhs>", ..., desc = "..." }
    # First find all keys = { ... } blocks
    for block_m in re.finditer(r"keys\s*=\s*\{", content):
        block_start = block_m.end() - 1
        block_end = find_matching_brace(content, block_start)
        if block_end == -1:
            continue
        block = content[block_start : block_end + 1]

        # Find entries in the block: { "...", ... desc = "..." }
        for entry_m in re.finditer(r"""\{\s*['"]([^'"]+)['"]\s*,""", block):
            entry_start = entry_m.start()
            entry_lhs = entry_m.group(1)
            # Find the matching closing brace for this entry
            entry_end = find_matching_brace(block, block.find("{", entry_start))
            if entry_end == -1:
                continue
            entry_block = block[entry_start : entry_end + 1]
            dm = re.search(r"""desc\s*=\s*['"]([^'"]+)['"]""", entry_block)
            if not dm:
                continue
            desc = dm.group(1)
            mode = "n"
            mode_m = re.search(r"""mode\s*=\s*['"](\w+)['"]""", entry_block)
            if mode_m:
                mode = mode_m.group(1)
            keymaps.append((mode, entry_lhs, desc, fname))

    return keymaps


def main():
    all_keymaps = []

    for starter_name, root in sorted(STARTER_DIRS.items()):
        for fp in find_lua_files(root):
            try:
                for km in extract_keymaps(fp):
                    all_keymaps.append((starter_name,) + km)
            except Exception as e:
                print(f"Error in {fp}: {e}", file=sys.stderr)

    # Deduplicate
    seen = set()
    unique = []
    for starter, mode, lhs, desc, fname in all_keymaps:
        key = (lhs, desc)
        if key not in seen:
            seen.add(key)
            unique.append((starter, mode, lhs, desc, fname))

    if not unique:
        print("No keymaps found.")
        return

    # Categorize and group
    by_cat = defaultdict(list)
    for starter, mode, lhs, desc, fname in unique:
        cat = categorize(desc, fname)
        by_cat[cat].append((starter, mode, lhs, desc, fname))

    cat_order = [
        "Search", "File", "LSP", "Git", "Debug", "Test",
        "Diagnostics", "Window/Buffer", "Terminal", "AI",
        "Hex", "Markdown", "Zen", "Writing", "Format",
        "Other",
    ]

    for cat in cat_order:
        if cat not in by_cat:
            continue
        items = by_cat[cat]
        items.sort(key=lambda x: (len(x[2]), x[2]))
        print(f"## {cat}\n")
        print("| Key | Action | Mode |")
        print("|-----|--------|------|")
        for starter, mode, lhs, desc, fname in items:
            display = lhs.replace("<leader>", "SPC").replace("<Leader>", "SPC")
            display = display.replace("<", "&lt;").replace(">", "&gt;")
            print(f"| `{display}` | {desc} | {mode} |")
        print()


if __name__ == "__main__":
    main()
