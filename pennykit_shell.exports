#!/usr/bin/env bash

export EDITOR="nvim"
export VISUAL="nvim"

export HISTSIZE=10000
export HISTCONTROL=ignoredups

export PATH="/usr/local/go/bin:${PATH}"
export PATH="${HOME}/.local/go/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/.opam/5.2.0+ox/bin:${PATH}"
export PATH="${HOME}/.npm-global/bin:${PATH}"
export PATH="${HOME}/.pennykit/bin:${PATH}"

# https://github.com/sharkdp/vivid/tree/master/themes
if command -v vivid >/dev/null 2>&1; then
  export LS_COLORS
  LS_COLORS="$(vivid generate gruvbox-dark-soft)"
fi

export LANG=ru_RU.UTF-8
# export LC_ALL=C.UTF-8

export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!.git/'"
# BUG: export FZF_CTRL_T_OPTS="--bind 'enter:become(nvim {})'"
export FZF_CTRL_T_OPTS=" \
  --preview 'batcat -n --color=always {}' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' \
  --height '50%' --reverse"


