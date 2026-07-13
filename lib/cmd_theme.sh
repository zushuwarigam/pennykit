#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Theme management command

cmd_theme() {
    cd "$PENNYKIT_HOME" || return

    if [[ "${1:-}" == "list" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "Available themes:"
        for f in configs/themes/*.conf; do
            echo "  $(basename "$f" .conf)"
        done
        return
    fi

    local theme_name=""
    local dry_run=""
    local parsed=()
    for arg in "$@"; do
        [[ "$arg" == "--dry-run" ]] && dry_run="--dry-run" || parsed+=("$arg")
    done
    set -- "${parsed[@]}"
    theme_name="${1:-}"
    if [[ -z "$theme_name" ]]; then
        local active=""
        [[ -f configs/theme.conf ]] && active=$(grep '^PENNYKIT_THEME=' configs/theme.conf | cut -d= -f2 | tr -d '"')
        echo "Current theme: ${GREEN}${active:-none}${RESET}"
        echo "Available themes:"
        for f in configs/themes/*.conf; do
            local name
            name=$(basename "$f" .conf)
            [[ "$name" == "$active" ]] && echo "  ${GREEN}$name (active)${RESET}" || echo "  $name"
        done
        return
    fi

    if [[ "$theme_name" == *".."* || "$theme_name" == *"/"* ]]; then
        echo "Error: invalid theme name '${theme_name}' (path separators not allowed)" >&2
        exit 1
    fi
    local theme_file="configs/themes/${theme_name}.conf"
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: theme '${theme_name}' not found"
        echo "Available themes:"
        for f in configs/themes/*.conf; do echo "  $(basename "$f" .conf)"; done
        exit 1
    fi

    # Try Python-driven declarative apply (reads theme_mapping.toml)
    if command -v python3 >/dev/null 2>&1; then
        if python3 scripts/util/apply_theme.py "$theme_name" $dry_run 2>/dev/null; then
            return
        fi
        echo "${YELLOW}Python apply failed, falling back to built-in...${RESET}"
    fi

    # ── Built-in fallback (kept for environments without python3) ──

    local required_vars=(
        PENNYKIT_THEME_NAME PENNYKIT_THEME_WEZTERM_LINUX PENNYKIT_THEME_WEZTERM_MACOS
        PENNYKIT_THEME_BAT PENNYKIT_THEME_YAZI PENNYKIT_THEME_VIVID
        PENNYKIT_THEME_HARLEQUIN PENNYKIT_THEME_NVIM PENNYKIT_THEME_LAZYGIT_BORDER
        PENNYKIT_THEME_TMUX PENNYKIT_THEME_OMB PENNYKIT_THEME_OMZ PENNYKIT_THEME_LF
    )
    source "$theme_file"
    local missing=false
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Warning: theme '${theme_name}' is missing required variable: $var"
            missing=true
        fi
    done
    [[ "$missing" == "true" ]] && die "Theme file is incomplete: ${theme_file}"

    echo "${GREEN}Applying theme (fallback):${RESET} $PENNYKIT_THEME_NAME"

    printf 'return { linux = "%s", macos = "%s" }\n' \
        "$PENNYKIT_THEME_WEZTERM_LINUX" "$PENNYKIT_THEME_WEZTERM_MACOS" \
        > configs/wezterm/_local_theme.lua
    echo "  WezTerm: $PENNYKIT_THEME_WEZTERM_LINUX / $PENNYKIT_THEME_WEZTERM_MACOS"

    grep -q '^--theme=' configs/bat/config 2>/dev/null \
        && sed -i "s/^--theme=\".*\"/--theme=\"${PENNYKIT_THEME_BAT}\"/" configs/bat/config \
        && echo "  bat: $PENNYKIT_THEME_BAT"

    if grep -q '^use = ' configs/yazi/theme.toml 2>/dev/null; then
        sed -i "s|^use = \".*\"|use = \"${PENNYKIT_THEME_YAZI}\"|" configs/yazi/theme.toml
        echo "  yazi: $PENNYKIT_THEME_YAZI"
        command -v ya >/dev/null 2>&1 \
            && ya pack -a "$PENNYKIT_THEME_YAZI" 2>/dev/null \
            || ya pkg add "$PENNYKIT_THEME_YAZI" 2>/dev/null || true
    fi

    grep -q 'vivid generate' shell/exports.sh 2>/dev/null \
        && sed -i "s/vivid generate .*/vivid generate ${PENNYKIT_THEME_VIVID})\"/" shell/exports.sh \
        && echo "  LS_COLORS (vivid): $PENNYKIT_THEME_VIVID"

    grep -q '\-\-theme' shell/aliases.sh 2>/dev/null \
        && sed -i "s|--theme [a-zA-Z0-9_/-]*|--theme ${PENNYKIT_THEME_HARLEQUIN}|" shell/aliases.sh \
        && echo "  harlequin: $PENNYKIT_THEME_HARLEQUIN"

    grep -q 'activeBorderColor:' configs/lazygit/config.yml 2>/dev/null \
        && sed -i "s/activeBorderColor: \[.*, bold\]/activeBorderColor: [${PENNYKIT_THEME_LAZYGIT_BORDER}, bold]/" configs/lazygit/config.yml \
        && echo "  lazygit: $PENNYKIT_THEME_LAZYGIT_BORDER"

    printf 'return { colorscheme = "%s" }\n' "$PENNYKIT_THEME_NVIM" \
        > configs/shared/nvim_colorscheme.lua
    echo "  Neovim: $PENNYKIT_THEME_NVIM"

    local tmux_theme="configs/tmux/tmux_theme.conf"
    if [[ -f "$tmux_theme" ]]; then
        case "${PENNYKIT_THEME_TMUX:-minimal}" in
            minimal)   printf '%s\n' '# minimal theme' > "$tmux_theme" ;;
            catppuccin) cat > "$tmux_theme" << 'TMUXEOF'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux#v2.1.3'
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
                ;;
            dracula) cat > "$tmux_theme" << 'TMUXEOF'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'dracula/tmux'
set -g @dracula-show-powerline true
set -g @dracula-show-flags true
set -g @dracula-show-left-icon session
set -g status-position bottom
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
                ;;
        esac
        echo "  tmux: $PENNYKIT_THEME_TMUX"
    fi

    local lf_rc="configs/lf/lfrc"
    if [[ -f "$lf_rc" ]] && grep -q 'set promptfmt' "$lf_rc" 2>/dev/null; then
        sed -i "/set promptfmt/ s/\\\\033\\[[1-9][0-9]*m/\\\\033[${PENNYKIT_THEME_LF}m/g" "$lf_rc"
        sed -i "/set promptfmt/ s/\\\\033\\[1;[1-9][0-9]*m/\\\\033[1;${PENNYKIT_THEME_LF}m/g" "$lf_rc"
        echo "  lf: color $PENNYKIT_THEME_LF"
    fi

    if [[ -f "${HOME}/.bashrc" ]] && grep -q '^OSH_THEME=' "${HOME}/.bashrc" 2>/dev/null; then
        sed -i "s/^OSH_THEME=\".*\"/OSH_THEME=\"${PENNYKIT_THEME_OMB}\"/" "${HOME}/.bashrc"
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

    echo "PENNYKIT_THEME=\"${theme_name}\"" > configs/theme.conf
    echo "Theme '$PENNYKIT_THEME_NAME' applied. Restart your apps to see changes."
}
