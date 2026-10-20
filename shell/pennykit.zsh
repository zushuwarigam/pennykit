source "${HOME}/.pennykit/shell/exports.sh"
source "${HOME}/.pennykit/shell/aliases.sh"
source "${HOME}/.pennykit/shell/functions.sh"

# clear screen
bindkey -r "^[l"
clear-screen-widget() { clear; zle redisplay; }
zle -N clear-screen-widget
bindkey '^[l' clear-screen-widget       # Alt+k

# open command in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\ee' edit-command-line
