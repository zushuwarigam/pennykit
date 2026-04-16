#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

if [[ -L "${HOME}/.tmux.conf" ]]; then
    unlink "${HOME}/.tmux.conf"
elif [[ -f "${HOME}/.tmux.conf" ]]; then
    mv -v "${HOME}/.tmux.conf" "${HOME}/.tmux.conf_$(date +%Y%m%d)"
fi

ln -s "${PENNYKIT_HOME}/configs/tmux/tmux.conf" "${HOME}/.tmux.conf"
