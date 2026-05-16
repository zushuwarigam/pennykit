#!/usr/bin/env bash
set -euo pipefail

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"

function _curl() {
  curl --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 60 "$@"
}
function _wget() {
  wget -c --tries=0 --waitretry=15 --timeout=60 --read-timeout=60 "$@"
}
export -f _curl _wget

usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [args]

Commands:
  (no command)       Show pennykit status dashboard
  nvim               Interactive nvim config switcher
  theme              Show current theme and available themes
  theme <name>       Apply a theme (e.g. $(basename "$0") theme catppuccin)
  extern [set]       Update external packages (set: default|admin|dev|pentest|all)
  extern deactivate <pkg>  Deactivate a package (skip install/update)
  extern activate <pkg>    Reactivate a deactivated package
  extern list-deactivated  List all deactivated packages
  update             Update pennykit itself (git pull --rebase)
  branch             Show current git branch
  branch <name>      Switch to a different git branch
  help               Show this help message

EOF
    exit 0
}

# ── Helpers ────────────────────────────────────────────────────

status() { echo "  $*"; }
die() { echo "Error: $*" >&2; exit 1; }

_is_deactivated() {
    local pkg="$1"
    local skip_file="$PENNYKIT_HOME/configs/extern.skip"
    [[ ! -f "$skip_file" ]] && return 1
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" == "$pkg" ]] && return 0
    done < "$skip_file"
    return 1
}

# ── Status dashboard ───────────────────────────────────────────

cmd_status() {
    echo ""
    echo "PennyKit status"
    echo "━━━━━━━━━━━━━━━━━━━"

    local branch
    branch=$(git -C "$PENNYKIT_HOME" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local commit
    commit=$(git -C "$PENNYKIT_HOME" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local remote
    remote=$(git -C "$PENNYKIT_HOME" remote get-url origin 2>/dev/null || echo "unknown")
    status "Repo:      $remote"
    status "Branch:    $branch ($commit)"

    local nvim_config="none"
    if [[ -L "$HOME/.config/nvim" ]]; then
        nvim_config=$(basename "$(readlink -f "$HOME/.config/nvim")")
    elif [[ -d "$HOME/.config/nvim" ]]; then
        nvim_config="custom dir"
    fi
    status "Nvim:      $nvim_config"

    local theme="none"
    if [[ -f "$PENNYKIT_HOME/configs/theme.conf" ]]; then
        theme=$(grep '^PENNYKIT_THEME=' "$PENNYKIT_HOME/configs/theme.conf" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "none")
    fi
    status "Theme:     $theme"

    source "$PENNYKIT_HOME/packages/extern.packages" >/dev/null 2>&1 || true
    local count_default=0 count_admin=0 count_dev=0 count_pentest=0
    [[ -v PENNYKIT_EXTERN_DEFAULT ]] && count_default=${#PENNYKIT_EXTERN_DEFAULT[@]}
    [[ -v PENNYKIT_EXTERN_ADMIN ]]   && count_admin=${#PENNYKIT_EXTERN_ADMIN[@]}
    [[ -v PENNYKIT_EXTERN_DEV ]]     && count_dev=${#PENNYKIT_EXTERN_DEV[@]}
    [[ -v PENNYKIT_EXTERN_PENTEST ]] && count_pentest=${#PENNYKIT_EXTERN_PENTEST[@]}
    status "Extern:    $count_default default, $count_admin admin, $count_dev dev, $count_pentest pentest"

    local deactivated=0
    if [[ -f "$PENNYKIT_HOME/configs/extern.skip" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            ((++deactivated))
        done < "$PENNYKIT_HOME/configs/extern.skip"
    fi
    [[ $deactivated -gt 0 ]] && status "Deactivated: $deactivated packages"

    echo ""
}

# ── nvim config switcher ───────────────────────────────────────

cmd_nvim() {
    local configs=()
    mapfile -t configs < <(find "${PENNYKIT_HOME}/nvim-starter" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    configs+=("Disable nvim config")

    PS3="Enter your choice: "
    select i in "${configs[@]}"; do
        if [[ -n "$i" ]]; then
            if [[ "$i" =~ ^Disable ]]; then
                if [[ -L "$HOME/.config/nvim" ]]; then
                    if [[ "$(readlink -f "$HOME/.config/nvim")" == *nvim-starter* ]]; then
                        unlink "$HOME/.config/nvim"
                    fi
                fi
            else
                if [[ -d "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
                    break
                elif [[ -L "$HOME/.config/nvim" ]]; then
                    if [[ "$(readlink -f "$HOME/.config/nvim")" == *nvim-starter* ]]; then
                        unlink "$HOME/.config/nvim"
                        ln -s "$i" "$HOME/.config/nvim"
                        rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
                    fi
                else
                    ln -s "$i" "$HOME/.config/nvim"
                fi
            fi
            break
        fi
    done
}

# ── Theme ──────────────────────────────────────────────────────

cmd_theme() {
    cd "$PENNYKIT_HOME"

    if [[ "${1:-}" == "list" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "Available themes:"
        for f in configs/themes/*.conf; do
            echo "  $(basename "$f" .conf)"
        done
        return
    fi

    local theme_name="${1:-}"
    if [[ -z "$theme_name" ]]; then
        if [[ -f configs/theme.conf ]]; then
            theme_name=$(grep '^PENNYKIT_THEME=' configs/theme.conf | cut -d= -f2 | tr -d '"')
        fi
        if [[ -z "$theme_name" ]]; then
            echo "No active theme. Available themes:"
            for f in configs/themes/*.conf; do echo "  $(basename "$f" .conf)"; done
            return
        fi
    fi

    local theme_file="configs/themes/${theme_name}.conf"
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: theme '${theme_name}' not found"
        echo "Available themes:"
        for f in configs/themes/*.conf; do echo "  $(basename "$f" .conf)"; done
        exit 1
    fi

    source "$theme_file"
    echo "Applying theme: $PENNYKIT_THEME_NAME"

    # WezTerm (Linux)
    if grep -q 'config.color_scheme' configs/wezterm/wezterm.lua 2>/dev/null; then
        sed -i "s/config.color_scheme = \".*\"/config.color_scheme = \"${PENNYKIT_THEME_WEZTERM_LINUX}\"/" configs/wezterm/wezterm.lua
        echo "  WezTerm (Linux): $PENNYKIT_THEME_WEZTERM_LINUX"
    fi

    # WezTerm (macOS)
    if grep -q 'config.color_scheme' configs/wezterm/wezterm_macos.lua 2>/dev/null; then
        sed -i "s/config.color_scheme = \".*\"/config.color_scheme = \"${PENNYKIT_THEME_WEZTERM_MACOS}\"/" configs/wezterm/wezterm_macos.lua
        echo "  WezTerm (macOS): $PENNYKIT_THEME_WEZTERM_MACOS"
    fi

    # bat
    if grep -q '^--theme=' configs/bat/config 2>/dev/null; then
        sed -i "s/^--theme=\".*\"/--theme=\"${PENNYKIT_THEME_BAT}\"/" configs/bat/config
        echo "  bat: $PENNYKIT_THEME_BAT"
    fi

    # yazi
    if grep -q '^use = ' configs/yazi/theme.toml 2>/dev/null; then
        sed -i "s|^use = \".*\"|use = \"${PENNYKIT_THEME_YAZI}\"|" configs/yazi/theme.toml
        echo "  yazi flavor: $PENNYKIT_THEME_YAZI"
        if command -v ya >/dev/null 2>&1; then
            ya pack -a "$PENNYKIT_THEME_YAZI" 2>/dev/null || ya pkg add "$PENNYKIT_THEME_YAZI" 2>/dev/null || true
        fi
    fi

    # vivid
    if grep -q 'vivid generate' pennykit_shell.exports 2>/dev/null; then
        sed -i "s/vivid generate .*/vivid generate ${PENNYKIT_THEME_VIVID}/" pennykit_shell.exports
        echo "  LS_COLORS (vivid): $PENNYKIT_THEME_VIVID"
    fi

    # harlequin
    if grep -q '\-\-theme' pennykit_shell.alias 2>/dev/null; then
        sed -i "s|--theme [a-zA-Z0-9_/-]*|--theme ${PENNYKIT_THEME_HARLEQUIN}|" pennykit_shell.alias
        echo "  harlequin: $PENNYKIT_THEME_HARLEQUIN"
    fi

    # lazygit
    if grep -q 'activeBorderColor:' configs/lazygit/config.yml 2>/dev/null; then
        sed -i "s/activeBorderColor: \[.*, bold\]/activeBorderColor: [${PENNYKIT_THEME_LAZYGIT_BORDER}, bold]/" configs/lazygit/config.yml
        echo "  lazygit border: $PENNYKIT_THEME_LAZYGIT_BORDER"
    fi

    # nvim astronvim_v6
    if [[ -f nvim-starter/astronvim_v6/lua/plugins/astroui.lua ]]; then
        sed -i "s/colorscheme = \".*\"/colorscheme = \"${PENNYKIT_THEME_NVIM}\"/" nvim-starter/astronvim_v6/lua/plugins/astroui.lua
        echo "  Neovim (astronvim_v6): $PENNYKIT_THEME_NVIM"
    fi

    # nvim lazyvim
    if [[ -f nvim-starter/lazyvim/lua/plugins/colorscheme.lua ]]; then
        sed -i "s/colorscheme = \".*\"/colorscheme = \"${PENNYKIT_THEME_NVIM}\"/" nvim-starter/lazyvim/lua/plugins/colorscheme.lua
        echo "  Neovim (lazyvim): $PENNYKIT_THEME_NVIM"
    fi

    # nvim kickstart
    local ks_init="nvim-starter/kickstart/init.lua"
    if [[ -f "$ks_init" ]]; then
        if grep -q "vim.cmd.colorscheme '" "$ks_init" 2>/dev/null; then
            sed -i "s/vim.cmd.colorscheme '.*'/vim.cmd.colorscheme '${PENNYKIT_THEME_NVIM}'/" "$ks_init"
        fi
        if grep -q 'vim.cmd.*colorscheme' "$ks_init" 2>/dev/null; then
            sed -i "s/vim.cmd \[\[colorscheme .*\]\]/vim.cmd [[colorscheme ${PENNYKIT_THEME_NVIM}]]/" "$ks_init"
        fi
        echo "  Neovim (kickstart): $PENNYKIT_THEME_NVIM"
    fi

    # tmux
    local tmux_conf="configs/tmux/tmux.conf"
    if [[ -f "$tmux_conf" ]]; then
        case "${PENNYKIT_THEME_TMUX:-minimal}" in
            minimal)
                sed -i '/^set -g @plugin/d' "$tmux_conf"
                sed -i '/^run .*tpm\/tpm$/d' "$tmux_conf"
                sed -i '/^set -g @dracula/d' "$tmux_conf"
                sed -i '/^set -g status-position/d' "$tmux_conf"
                echo "  tmux: minimal"
                ;;
            catppuccin)
                sed -i '/^set -g @plugin/d' "$tmux_conf"
                sed -i '/^run .*tpm\/tpm$/d' "$tmux_conf"
                sed -i '/^set -g @dracula/d' "$tmux_conf"
                sed -i '/^set -g status-position/d' "$tmux_conf"
                cat >> "$tmux_conf" << 'TMUXEOF'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux#v2.1.3'
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
                echo "  tmux: catppuccin"
                ;;
            dracula)
                sed -i '/^set -g @plugin/d' "$tmux_conf"
                sed -i '/^run .*tpm\/tpm$/d' "$tmux_conf"
                sed -i '/^set -g @dracula/d' "$tmux_conf"
                sed -i '/^set -g status-position/d' "$tmux_conf"
                cat >> "$tmux_conf" << 'TMUXEOF'

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
        esac
    fi

    # Shell themes
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
}

# ── Extern update ──────────────────────────────────────────────

_update_or_skip() {
    local pkg="$1"
    if _is_deactivated "$pkg"; then
        echo "  Skipping $pkg (deactivated)"
        return
    fi
    "update_$pkg"
}

cmd_extern() {
    cd "$PENNYKIT_HOME"
    local skip_file="configs/extern.skip"
    local cmd="${1:-}"

    case "$cmd" in
        deactivate)
            [[ -z "${2:-}" ]] && { echo "Usage: $(basename "$0") extern deactivate <package>"; exit 1; }
            if ! grep -qxF "$2" "$skip_file" 2>/dev/null; then
                echo "$2" >> "$skip_file"
                echo "Deactivated: $2"
            else
                echo "Already deactivated: $2"
            fi
            return
            ;;
        activate)
            [[ -z "${2:-}" ]] && { echo "Usage: $(basename "$0") extern activate <package>"; exit 1; }
            if [[ -f "$skip_file" ]]; then
                grep -vxF "$2" "$skip_file" > "$skip_file.tmp" && mv "$skip_file.tmp" "$skip_file"
                [[ ! -s "$skip_file" ]] && rm -f "$skip_file"
                echo "Activated: $2"
            fi
            return
            ;;
        list-deactivated)
            if [[ -f "$skip_file" ]]; then
                echo "Deactivated packages:"
                cat "$skip_file" | grep -v '^#'
            else
                echo "No deactivated packages."
            fi
            return
            ;;
    esac

    local set="${cmd:-default}"
    PENNYKIT_ON_CONTAINER=false
    source "./packages/extern.packages"

    case "$set" in
        default)
            [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
                && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _update_or_skip "$p"; done
            ;;
        admin)
            [[ -v PENNYKIT_EXTERN_ADMIN ]] \
                && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _update_or_skip "$p"; done
            ;;
        dev)
            [[ -v PENNYKIT_EXTERN_DEV ]] \
                && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _update_or_skip "$p"; done
            ;;
        pentest)
            [[ -v PENNYKIT_EXTERN_PENTEST ]] \
                && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _update_or_skip "$p"; done
            ;;
        all)
            [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
                && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_ADMIN ]] \
                && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_DEV ]] \
                && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_PENTEST ]] \
                && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _update_or_skip "$p"; done
            ;;
        *)
            echo "Usage: $(basename "$0") extern [default|admin|dev|pentest|all|deactivate|activate|list-deactivated]"
            exit 1
            ;;
    esac
}

# ── Self-update ────────────────────────────────────────────────

cmd_update() {
    echo "Updating pennykit..."
    git -C "$PENNYKIT_HOME" pull --rebase
    echo "Done."
}

# ── Branch operations ──────────────────────────────────────────

cmd_branch() {
    if [[ -z "${1:-}" ]]; then
        git -C "$PENNYKIT_HOME" branch
    else
        echo "Switching to branch: $1"
        git -C "$PENNYKIT_HOME" checkout "$1"
    fi
}

# ── Main dispatch ──────────────────────────────────────────────

case "${1:-}" in
    ""|status)     cmd_status ;;
    nvim)          cmd_nvim ;;
    theme)         shift; cmd_theme "$@" ;;
    extern)        shift; cmd_extern "$@" ;;
    update)        cmd_update ;;
    branch)        shift; cmd_branch "$@" ;;
    help|-h|--help) usage ;;
    *)             echo "Error: unknown command '$1'"; usage ;;
esac
