#!/usr/bin/env bash

function note() {
    mkdir -p ~/notes/05_timesheets ~/notes/01_inbox
    local opt
    while getopts ":dl" opt; do
        case $opt in
            d) # Timesheets note (YYYY-MM-DD.md)
                local file
                file=~/notes/05_timesheets/$(date +"%Y-%m-%d").md
                $EDITOR "$file"
                ;;
            l) # List existing notes with fzf
                local file
                file=$(fd . "$HOME/notes" \
                    | fzf \
                    --preview='batcat --color=always --style=numbers {}')
                if [[ -f "$file" ]]; then
                    $EDITOR "$file"
                fi
                ;;
            *)
                return
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ -n "$1" ]; then
        file=~/notes/01_inbox/$(date +"%Y-%m-%d-%H%M")-$1.md
        $EDITOR "$file"
    fi
}

function mkcd() { mkdir -p "$1" && cd "$1" || return; }
function serve() { python3 -m http.server "${1:-8000}"; }
function bak() { cp "$1"{,.bak}; echo "Backed up: $1.bak"; }
function orig() { cp "$1"{,.orig}; echo "Backed up: $1.orig"; }

function penny-update-extern() {
    case "${1:-}" in
        deactivate|activate|list-deactivated)
            bash "$PENNYKIT_HOME/bin/pennykit" extern "$@"
            ;;
        help|--help|-h)
            echo "Usage: penny-update-extern [set|subcommand]"
            echo ""
            echo "Sets:"
            echo "  (no arg)         Update default external packages"
            echo "  default          Update default set"
            echo "  admin            Update admin set"
            echo "  dev              Update dev set"
            echo "  pentest          Update pentest set"
            echo "  all              Update all sets"
            echo ""
            echo "Subcommands:"
            echo "  deactivate <pkg>     Deactivate a package (skip install/update)"
            echo "  activate <pkg>       Reactivate a deactivated package"
            echo "  list-deactivated     List all deactivated packages"
            ;;
        *)
            bash "$PENNYKIT_HOME/bin/pennykit" extern "${1:-default}"
            ;;
    esac
}

function penny-theme() {
    case "${1:-}" in
        list)
            bash "$PENNYKIT_HOME/bin/pennykit" theme list
            ;;
        set)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: penny-theme set <theme-name>"
                return 1
            fi
            echo "PENNYKIT_THEME=\"${2}\"" > "$PENNYKIT_HOME/configs/theme.conf"
            bash "$PENNYKIT_HOME/bin/pennykit" theme "$2"
            echo "Run 'source ~/.bashrc' (or restart shell) to apply prompt changes."
            ;;
        apply)
            bash "$PENNYKIT_HOME/bin/pennykit" theme
            ;;
        *)
            echo "Usage: penny-theme [list|set|apply]"
            echo "  list   - Show available themes"
            echo "  set    - Activate and apply a theme"
            echo "  apply  - Re-apply the current theme"
            ;;
    esac
}

function fzf_rg_nvim() {
    local result file line
    result=$(rg --line-number --color=never ".?" \
        | fzf --delimiter=: \
        --preview='batcat --color=always --highlight-line {2} --color=always {1}' \
        --preview-window='right:60%')
    if [[ -n "$result" ]]; then
        file=$(cut -d: -f1 <<< "$result")
        line=$(cut -d: -f2 <<< "$result")
        nvim "+$line" "$file"
    fi
}

# Bind
if [[ "$(basename "$SHELL")" == "bash" ]]; then
    bind -x '"\C-f": fzf_rg_nvim'
elif [[ "$(basename "$SHELL")" == "zsh"  ]]; then
    zle -N fzf_rg_nvim
    bindkey '^F' fzf_rg_nvim
fi

