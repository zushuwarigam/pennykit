#!/usr/bin/env bash
set -euo pipefail

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"

cd "$PENNYKIT_HOME"

usage() {
    cat <<EOF
Usage: $(basename "$0") [theme-name]

Apply a theme to all TUI app configs. If no theme is specified,
uses the active theme from configs/theme.conf.

Available themes:
$(for f in configs/themes/*.conf; do basename "$f" .conf; done)

Options:
  -h, --help  Show this help message and exit

EOF
    exit 0
}

case "${1:-}" in
    -h|--help) usage ;;
esac

if [[ -n "${1:-}" ]]; then
    PENNYKIT_THEME="$1"
fi

# Source active theme config
THEME_FILE="${PENNYKIT_HOME}/configs/themes/${PENNYKIT_THEME}.conf"
if [[ ! -f "$THEME_FILE" ]]; then
    echo "Error: theme '${PENNYKIT_THEME}' not found"
    echo "Available themes:"
    for f in configs/themes/*.conf; do echo "  $(basename "$f" .conf)"; done
    exit 1
fi

source "$THEME_FILE"

echo "Applying theme: $PENNYKIT_THEME_NAME"

# ── WezTerm (Linux) ───────────────────────────────────────────
if grep -q 'config.color_scheme' configs/wezterm/wezterm.lua 2>/dev/null; then
    sed -i "s/config.color_scheme = \".*\"/config.color_scheme = \"${PENNYKIT_THEME_WEZTERM_LINUX}\"/" configs/wezterm/wezterm.lua
    echo "  WezTerm (Linux): $PENNYKIT_THEME_WEZTERM_LINUX"
fi

# ── WezTerm (macOS) ───────────────────────────────────────────
if grep -q 'config.color_scheme' configs/wezterm/wezterm_macos.lua 2>/dev/null; then
    sed -i "s/config.color_scheme = \".*\"/config.color_scheme = \"${PENNYKIT_THEME_WEZTERM_MACOS}\"/" configs/wezterm/wezterm_macos.lua
    echo "  WezTerm (macOS): $PENNYKIT_THEME_WEZTERM_MACOS"
fi

# ── bat ────────────────────────────────────────────────────────
if grep -q '^--theme=' configs/bat/config 2>/dev/null; then
    sed -i "s/^--theme=\".*\"/--theme=\"${PENNYKIT_THEME_BAT}\"/" configs/bat/config
    echo "  bat: $PENNYKIT_THEME_BAT"
fi

# ── yazi ───────────────────────────────────────────────────────
if grep -q '^use = ' configs/yazi/theme.toml 2>/dev/null; then
    sed -i "s|^use = \".*\"|use = \"${PENNYKIT_THEME_YAZI}\"|" configs/yazi/theme.toml
    echo "  yazi flavor: $PENNYKIT_THEME_YAZI"

    # Install flavor via ya if available
    if command -v ya >/dev/null 2>&1; then
        ya pack -a "$PENNYKIT_THEME_YAZI" 2>/dev/null || ya pkg add "$PENNYKIT_THEME_YAZI" 2>/dev/null || \
            echo "  (warning: could not install yazi flavor, install manually with 'ya pack -a $PENNYKIT_THEME_YAZI')"
    fi
fi

# ── vivid (LS_COLORS) ──────────────────────────────────────────
if grep -q 'vivid generate' pennykit_shell.exports 2>/dev/null; then
    sed -i "s/vivid generate .*/vivid generate ${PENNYKIT_THEME_VIVID}/" pennykit_shell.exports
    echo "  LS_COLORS (vivid): $PENNYKIT_THEME_VIVID"
fi

# ── harlequin ──────────────────────────────────────────────────
if grep -q '\-\-theme' pennykit_shell.alias 2>/dev/null; then
    sed -i "s/--theme [a-zA-Z0-9_-]*/--theme ${PENNYKIT_THEME_HARLEQUIN}/" pennykit_shell.alias
    echo "  harlequin: $PENNYKIT_THEME_HARLEQUIN"
fi

# ── lazygit ────────────────────────────────────────────────────
if grep -q 'activeBorderColor:' configs/lazygit/config.yml 2>/dev/null; then
    sed -i "s/activeBorderColor: \[.*, bold\]/activeBorderColor: [${PENNYKIT_THEME_LAZYGIT_BORDER}, bold]/" configs/lazygit/config.yml
    echo "  lazygit border: $PENNYKIT_THEME_LAZYGIT_BORDER"
fi

# ── Neovim: astronvim_v6 ───────────────────────────────────────
if [[ -f nvim-starter/astronvim_v6/lua/plugins/astroui.lua ]]; then
    sed -i "s/colorscheme = \".*\"/colorscheme = \"${PENNYKIT_THEME_NVIM}\"/" nvim-starter/astronvim_v6/lua/plugins/astroui.lua
    echo "  Neovim (astronvim_v6): $PENNYKIT_THEME_NVIM"
fi

# ── Neovim: lazyvim ────────────────────────────────────────────
if [[ -f nvim-starter/lazyvim/lua/plugins/colorscheme.lua ]]; then
    sed -i "s/colorscheme = \".*\"/colorscheme = \"${PENNYKIT_THEME_NVIM}\"/" nvim-starter/lazyvim/lua/plugins/colorscheme.lua
    echo "  Neovim (lazyvim): $PENNYKIT_THEME_NVIM"
fi

# ── Neovim: kickstart ──────────────────────────────────────────
KICKSTART_INIT="nvim-starter/kickstart/init.lua"
if [[ -f "$KICKSTART_INIT" ]]; then
    # Line 897: vim.cmd.colorscheme '...'
    if grep -q "vim.cmd.colorscheme '" "$KICKSTART_INIT" 2>/dev/null; then
        sed -i "s/vim.cmd.colorscheme '.*'/vim.cmd.colorscheme '${PENNYKIT_THEME_NVIM}'/" "$KICKSTART_INIT"
    fi
    # Line 1017: vim.cmd [[colorscheme ...]]
    if grep -q 'vim.cmd.*colorscheme' "$KICKSTART_INIT" 2>/dev/null; then
        sed -i "s/vim.cmd \[\[colorscheme .*\]\]/vim.cmd [[colorscheme ${PENNYKIT_THEME_NVIM}]]/" "$KICKSTART_INIT"
    fi
    echo "  Neovim (kickstart): $PENNYKIT_THEME_NVIM"
fi

# ── tmux ───────────────────────────────────────────────────────
TMUX_CONF="configs/tmux/tmux.conf"
if [[ -f "$TMUX_CONF" ]]; then
    case "$PENNYKIT_THEME_TMUX" in
        minimal)
            sed -i '/^set -g @plugin/d' "$TMUX_CONF"
            sed -i '/^run .*tpm\/tpm$/d' "$TMUX_CONF"
            sed -i '/^set -g @dracula/d' "$TMUX_CONF"
            sed -i '/^set -g status-position/d' "$TMUX_CONF"
            echo "  tmux: minimal (no theme plugin)"
            ;;
        catppuccin)
            sed -i '/^set -g @plugin/d' "$TMUX_CONF"
            sed -i '/^run .*tpm\/tpm$/d' "$TMUX_CONF"
            sed -i '/^set -g @dracula/d' "$TMUX_CONF"
            sed -i '/^set -g status-position/d' "$TMUX_CONF"
            cat >> "$TMUX_CONF" << 'TMUXEOF'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux#v2.1.3'
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
            echo "  tmux: catppuccin"
            ;;
        dracula)
            sed -i '/^set -g @plugin/d' "$TMUX_CONF"
            sed -i '/^run .*tpm\/tpm$/d' "$TMUX_CONF"
            sed -i '/^set -g @dracula/d' "$TMUX_CONF"
            sed -i '/^set -g status-position/d' "$TMUX_CONF"
            cat >> "$TMUX_CONF" << 'TMUXEOF'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'dracula/tmux'
set -g @dracula-show-powerline true
set -g @dracula-show-flags true
set -g @dracula-show-left-icon session
set -g status-position bottom
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
            echo "  tmux: dracula"
            ;;
        *)
            echo "  tmux: unknown theme '${PENNYKIT_THEME_TMUX}', skipping"
            ;;
    esac
fi

# ── Shell themes (user home) ───────────────────────────────────
if [[ -f "${HOME}/.bashrc" ]]; then
    sed -i "s/^OSH_THEME=\".*\"/OSH_THEME=\"${PENNYKIT_THEME_OMB}\"/" "${HOME}/.bashrc" 2>/dev/null || true
    echo "  Oh My Bash: $PENNYKIT_THEME_OMB"
fi

if [[ -f "${HOME}/.zshrc" ]]; then
    if grep -q '^ZSH_THEME=' "${HOME}/.zshrc" 2>/dev/null; then
        sed -i "s/^ZSH_THEME=\".*\"/ZSH_THEME=\"${PENNYKIT_THEME_OMZ}\"/" "${HOME}/.zshrc"
    else
        echo "ZSH_THEME=\"${PENNYKIT_THEME_OMZ}\"" >> "${HOME}/.zshrc"
    fi
    echo "  Oh My Zsh: $PENNYKIT_THEME_OMZ"
fi

echo "Theme '$PENNYKIT_THEME_NAME' applied. Restart your apps to see changes."
