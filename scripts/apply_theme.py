#!/usr/bin/env python3
"""
Apply a pennykit theme using the declarative mapping in theme_mapping.toml.

Usage:
    ./apply_theme.py <theme_name> [--dry-run]

Reads configs/theme_mapping.toml for the app→file→operation mapping,
then reads configs/themes/<theme_name>.conf for variable values.
Replaces %VAR% placeholders with the corresponding PENNYKIT_THEME_<VAR> values.
"""

import re
import os
import sys
import shlex
import string
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PENNYKIT_HOME = os.environ.get("PENNYKIT_HOME", os.path.dirname(HERE))

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: need Python 3.11+ or 'pip install tomli'", file=sys.stderr)
        sys.exit(1)


def read_theme_conf(theme_name):
    path = os.path.join(PENNYKIT_HOME, "configs", "themes", f"{theme_name}.conf")
    vars_ = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, val = line.partition("=")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            # Strip PENNYKIT_THEME_ prefix and store
            short = key.replace("PENNYKIT_THEME_", "", 1)
            vars_[short] = val
    return vars_


def resolve_path(path_spec):
    """Resolve a path like {HOME}/.bashrc or configs/..."""
    path_spec = path_spec.replace("{HOME}", os.path.expanduser("~"))
    if not os.path.isabs(path_spec):
        path_spec = os.path.join(PENNYKIT_HOME, path_spec)
    return os.path.normpath(path_spec)


def subst(text, vars_):
    def replacer(m):
        key = m.group(1)
        return vars_.get(key, m.group(0))
    return re.sub(r"%([A-Z_0-9]+)%", replacer, text)


def apply_tmux(entry, vars_, dry_run):
    theme_val = vars_.get(entry["variable"], "minimal")
    path = resolve_path(entry["file"])
    tmux_themes = {
        "minimal": "# minimal theme (no status bar plugins)\n",
        "catppuccin": (
            'set -g @plugin \'tmux-plugins/tpm\'\n'
            'set -g @plugin \'catppuccin/tmux#v2.1.3\'\n'
            'run \'~/.tmux/plugins/tpm/tpm\'\n'
        ),
        "dracula": (
            'set -g @plugin \'tmux-plugins/tpm\'\n'
            'set -g @plugin \'dracula/tmux\'\n'
            'set -g @dracula-show-powerline true\n'
            'set -g @dracula-show-flags true\n'
            'set -g @dracula-show-left-icon session\n'
            'set -g status-position bottom\n'
            'run \'~/.tmux/plugins/tpm/tpm\'\n'
        ),
    }
    content = tmux_themes.get(theme_val, tmux_themes["minimal"])
    label = f"  tmux: {theme_val}"
    if dry_run:
        print(f"  [DRY-RUN] Write {path}")
        print(label)
        return label
    with open(path, "w") as f:
        f.write(content)
    print(label)
    return label


def apply_template(entry, vars_, dry_run):
    path = resolve_path(entry["file"])
    content = subst(entry["template"], vars_)
    label = f"  {entry.get('label', os.path.basename(path))}: written"
    if dry_run:
        print(f"  [DRY-RUN] Write {path}: {content}")
        print(label)
        return label
    with open(path, "w") as f:
        f.write(content + "\n")
    print(label)
    return label


def apply_sed(entry, vars_, dry_run):
    path = resolve_path(entry["file"])
    search = subst(entry["search"], vars_)
    replace = subst(entry["replace"], vars_)
    grep_check = subst(entry.get("grep", ""), vars_)

    if not os.path.exists(path):
        return None

    if grep_check:
        with open(path) as f:
            if not re.search(grep_check, f.read(), re.MULTILINE):
                print(f"  {os.path.basename(path)}: pattern not found, skipping")
                return None

    label = f"  {entry.get('label', os.path.basename(path))}: {replace[:60]}"
    if dry_run:
        print(f"  [DRY-RUN] sed -i 's/{search}/{replace}/' {path}")
        print(label)
        return label

    with open(path) as f:
        content = f.read()
    content = re.sub(search, replace, content)
    with open(path, "w") as f:
        f.write(content)

    # Handle extra_sed (e.g., lf second pass)
    extra = entry.get("extra_sed")
    if extra:
        extra_search = subst(extra["search"], vars_)
        extra_replace = subst(extra["replace"], vars_)
        with open(path) as f:
            content = f.read()
        content = re.sub(extra_search, extra_replace, content)
        with open(path, "w") as f:
            f.write(content)

    print(label)
    return label


def apply_sed_or_append(entry, vars_, dry_run):
    path = resolve_path(entry["file"])
    search = subst(entry["search"], vars_)
    replace = subst(entry["replace"], vars_)
    append = subst(entry["append"], vars_)
    grep_check = subst(entry.get("grep", ""), vars_)

    if not os.path.exists(path):
        return None

    with open(path) as f:
        content = f.read()
    if grep_check and re.search(grep_check, content, re.MULTILINE):
        label = f"  {os.path.basename(path)}: {replace[:60]}"
        if dry_run:
            print(f"  [DRY-RUN] sed -i 's/{search}/{replace}/' {path}")
            print(label)
            return label
        content = re.sub(search, replace, content)
        with open(path, "w") as f:
            f.write(content)
    else:
        label = f"  {os.path.basename(path)}: {append[:60]} (appended)"
        if dry_run:
            print(f"  [DRY-RUN] echo '{append}' >> {path}")
            print(label)
            return label
        with open(path, "a") as f:
            f.write(append + "\n")
    print(label)
    return label


def apply_sed_lf(entry, vars_, dry_run):
    """Handle lf promptfmt sed — the file contains literal \\033[ escape sequences."""
    path = resolve_path(entry["file"])
    grep_check = entry.get("grep", "")
    color = vars_.get(entry["variable"], "32")

    if not os.path.exists(path):
        return None

    with open(path) as f:
        content = f.read()
    if grep_check and grep_check not in content:
        print(f"  lf: pattern not found, skipping")
        return None

    label = f"  lf prompt: color {color}"
    if dry_run:
        print(f"  [DRY-RUN] Update color to {color} in {path}")
        print(label)
        return label

    # Pass 1: replace \033[<color>m (color starts with 1-9) → \033[<LF>m
    content = re.sub(r'(\\033\[)([1-9][0-9]*)(m)', lambda m: m.group(1) + color + m.group(3), content)
    # Pass 2: replace \033[1;<color>m (bold variant) → \033[1;<LF>m
    content = re.sub(r'(\\033\[1;)([1-9][0-9]*)(m)', lambda m: m.group(1) + color + m.group(3), content)
    with open(path, "w") as f:
        f.write(content)
    print(label)
    return label


_SAFE_VAR_RE = re.compile(r'^[a-zA-Z0-9_.\-:@/]+$')

def _validate_post_cmd(cmd):
    for word in shlex.split(cmd):
        if word.startswith("/") or word.startswith("."):
            continue
        if word in ("true", "false", "||", "&&", "2>/dev/null", ">/dev/null"):
            continue
        if not _SAFE_VAR_RE.match(word):
            if not word.startswith("-"):
                return False
    return True

def apply_post_cmd(cmd, vars_, dry_run):
    cmd = subst(cmd, vars_)
    if not _validate_post_cmd(cmd):
        print(f"  WARNING: post_cmd blocked (unsafe characters): {cmd[:60]}", file=sys.stderr)
        return None
    label = f"  post: {cmd[:60]}"
    if dry_run:
        print(f"  [DRY-RUN] {cmd}")
        print(label)
        return label
    subprocess.run(cmd, shell=True, check=True)
    print(label)
    return label


def main():
    args = sys.argv[1:]
    theme_name = args[0] if args else None
    dry_run = "--dry-run" in args

    if not theme_name or theme_name in ("--help", "-h"):
        print(__doc__)
        return

    mapping_path = os.path.join(PENNYKIT_HOME, "configs", "theme_mapping.toml")
    with open(mapping_path, "rb") as f:
        mapping = tomllib.load(f)

    vars_ = read_theme_conf(theme_name)
    os.chdir(PENNYKIT_HOME)

    results = []
    for app_key, entry in sorted(mapping.get("apps", {}).items()):
        t = entry["type"]
        if t == "template":
            r = apply_template(entry, vars_, dry_run)
        elif t == "sed":
            r = apply_sed(entry, vars_, dry_run)
        elif t == "sed_or_append":
            r = apply_sed_or_append(entry, vars_, dry_run)
        elif t == "sed_lf":
            r = apply_sed_lf(entry, vars_, dry_run)
        elif t == "tmux_case":
            r = apply_tmux(entry, vars_, dry_run)
        else:
            print(f"  Unknown type '{t}' for {app_key}, skipping")
            continue
        if r:
            results.append(r)

        post = entry.get("post_cmd")
        if post:
            apply_post_cmd(post, vars_, dry_run)

    # Write theme.conf
    theme_conf = os.path.join(PENNYKIT_HOME, "configs", "theme.conf")
    content = f'PENNYKIT_THEME="{theme_name}"\n'
    if dry_run:
        print(f"  [DRY-RUN] Write {theme_conf}: {content.strip()}")
    else:
        with open(theme_conf, "w") as f:
            f.write(content)

    theme_display = vars_.get("NAME", theme_name)
    print(f"Theme '{theme_display}' applied. Restart your apps to see changes.")


if __name__ == "__main__":
    main()
