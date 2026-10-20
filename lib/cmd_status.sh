#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Status dashboard command

cmd_status() {
    echo ""
    echo "${BOLD}PennyKit status${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━${RESET}"

    local branch
    branch=$(git -C "$PENNYKIT_HOME" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local commit
    commit=$(git -C "$PENNYKIT_HOME" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local remote
    remote=$(git -C "$PENNYKIT_HOME" remote get-url origin 2>/dev/null || echo "unknown")
    status "${BOLD}Repo:${RESET}      $remote"
    status "${BOLD}Branch:${RESET}    $branch (${GREEN}$commit${RESET})"

    local nvim_config="none"
    if [[ -L "$HOME/.config/nvim" ]]; then
        nvim_config=$(basename "$(_readlinkf "$HOME/.config/nvim")")
    elif [[ -d "$HOME/.config/nvim" ]]; then
        nvim_config="custom dir"
    fi
    if [[ "$nvim_config" == "none" ]]; then
        status_yellow "${BOLD}Nvim:${RESET}      $nvim_config"
    else
        status_green "${BOLD}Nvim:${RESET}      $nvim_config"
    fi

    local theme="none"
    if [[ -f "$PENNYKIT_HOME/configs/theme.conf" ]]; then
        theme=$(grep '^PENNYKIT_THEME=' "$PENNYKIT_HOME/configs/theme.conf" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "none")
    fi
    if [[ "$theme" == "none" ]]; then
        status_yellow "${BOLD}Theme:${RESET}     $theme"
    else
        status_green "${BOLD}Theme:${RESET}     $theme"
    fi

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
