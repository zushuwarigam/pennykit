#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

mkdir -p "${HOME}/.config"
if [[ ! -d "${HOME}/.config/bat" ]]; then
    ln -s "${PENNYKIT_HOME}/configs/bat" "${HOME}/.config/bat"
fi
