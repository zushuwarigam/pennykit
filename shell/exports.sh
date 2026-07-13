#!/usr/bin/env bash

export EDITOR="nvim"
export VISUAL="nvim"

export HISTSIZE=10000
export HISTCONTROL=ignoredups

_add_path() { [[ -d "$1" ]] && export PATH="$1:${PATH}"; return 0; }
_add_path "/usr/local/go/bin"
_add_path "${HOME}/.local/go/bin"
_add_path "${HOME}/go/bin"
_add_path "${HOME}/.local/bin"
_add_path "${HOME}/.cargo/bin"
_add_path "${HOME}/.opam/5.2.0+ox/bin"
_add_path "${HOME}/.npm-global/bin"
_add_path "${HOME}/.pennykit/bin"
unset -f _add_path

# https://github.com/sharkdp/vivid/tree/master/themes
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS
  LS_COLORS="$(vivid generate gruvbox-dark-soft)"
fi

export LANG="${LANG:-en_US.UTF-8}"
# export LC_ALL=C.UTF-8

export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git/'"
# BUG: export FZF_CTRL_T_OPTS="--bind 'enter:become(nvim {})'"
export FZF_CTRL_T_OPTS=" \
  --preview 'batcat -n --color=always {}' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' \
  --height '50%' --reverse"


