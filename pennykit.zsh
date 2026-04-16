source "${HOME}/.pennykit/pennykit_shell.exports"
source "${HOME}/.pennykit/pennykit_shell.alias"
source "${HOME}/.pennykit/pennykit_shell.functions"

# clear screen
bindkey -r "^[l"

clear-screen-widget() { clear; zle redisplay; }
zle -N clear-screen-widget
bindkey '^[l' clear-screen-widget       # Alt+k

# list directory
#
# ls-widget() {
#   zle -I
#   print -r -- ""
#   ls -l
#   zle redisplay
# }
# zle -N ls-widget
# bindkey '^[k' ls-widget

