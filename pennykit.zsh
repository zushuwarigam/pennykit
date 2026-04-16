source "${HOME}/.pennykit/pennykit_shell.exports"
source "${HOME}/.pennykit/pennykit_shell.alias"
source "${HOME}/.pennykit/pennykit_shell.functions"

# clear screen
bindkey -r "^[l"
clear-screen-widget() { clear; zle redisplay; }
zle -N clear-screen-widget
bindkey '^[l' clear-screen-widget       # Alt+k

# open command in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\ee' edit-command-line
