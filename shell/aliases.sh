#!/usr/bin/env bash

alias v="nvim"
alias vi="nvim"
alias vim="nvim"

alias vz="nvim -c 'ZenMode'"
alias viz="nvim -c 'ZenMode'"
alias vimz="nvim -c 'ZenMode'"

# Git
alias gs="git status"
alias gl="git log"
alias glg="git log --oneline --graph --all"
alias glga="git log --graph --all --format='%C(yellow)%h%C(reset) %C(blue)%<(15)%an%C(reset) %s'"
alias gds="git diff --staged"

alias gpl="git pull"
alias gps="git push"

alias ga="git add"
alias gc="git commit"

alias gstl="git stash list"
alias gsta="git stash"
alias gstp="git stash pop"

alias gundo="git reset --soft HEAD~1"

alias gg="git log -i --all --grep"

# Docker
alias dsp="docker system prune"
alias di="docker images"
alias dps="docker ps -a"

alias ll="ls -l"
alias la="ls -a"
alias lla="ls -la"

alias fd="fdfind"

alias vimdiff="nvim -d"
alias gitmail="git send-email --suppress-cc=all"

alias mc="mc -b"

alias tn="tmux new -s"
alias tl="tmux ls"
alias ta="tmux a"

alias glow="glow -w \$((\$(tput cols) - 5)) -p"

# Bad connection
alias wget="wget -c -t 3 --retry-connrefused --read-timeout=20 --waitretry=1"

if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --theme="gruvbox-dark"'
fi

if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll="eza -l --git --header"
fi

if command -v lf >/dev/null 2>&1; then
  alias fm='lf'
fi

if command -v yazi >/dev/null 2>&1; then
  alias fm="yazi"
fi

if command -v fzf >/dev/null 2>&1; then
  :
  # eval "$(fzf --bash)"
  # alias ff="vim +\$(rg -n . | fzf | awk -F: '{print '+'\$2,\$1}')"
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg="lazygit"
fi

if command -v harlequin >/dev/null 2>&1; then
  alias harlequin="harlequin --theme gruvbox"
fi

alias pk-update="penny-update-extern"

