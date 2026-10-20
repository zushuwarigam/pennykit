#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Nvim config switcher command

_nvim_config_type() {
    if [[ -L "$HOME/.config/nvim" ]]; then
        local target
        target="$(_readlinkf "$HOME/.config/nvim")"
        if [[ "$target" == *nvim-starter* ]]; then
            echo "symlink"
        else
            echo "external_symlink"
        fi
    elif [[ -d "$HOME/.config/nvim" ]]; then
        echo "directory"
    else
        echo "none"
    fi
}

cmd_nvim() {
    local configs=()
    mapfile -t configs < <(find "${PENNYKIT_HOME}/nvim-starter" -maxdepth 1 -mindepth 1 -type d ! -name '*.git' 2>/dev/null)
    configs+=("Disable nvim config")

    PS3="Enter your choice: "
    select i in "${configs[@]}"; do
        if [[ -z "$i" ]]; then
            continue
        fi
        if [[ "$i" =~ ^Disable ]]; then
            if [[ "$(_nvim_config_type)" == "symlink" ]]; then
                unlink "$HOME/.config/nvim"
            fi
        elif [[ "$(_nvim_config_type)" == "symlink" ]]; then
            unlink "$HOME/.config/nvim"
            ln -s "$i" "$HOME/.config/nvim"
            rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
        elif [[ "$(_nvim_config_type)" == "none" ]]; then
            ln -s "$i" "$HOME/.config/nvim"
        fi
        break
    done
}
