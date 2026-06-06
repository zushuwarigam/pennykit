# shellcheck disable=SC1090,SC1091

_curl() {
  curl --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 60 "$@"
}
_wget() {
  wget -c --tries=0 --waitretry=15 --timeout=60 --read-timeout=60 "$@"
}
export -f _curl _wget

if [[ -t 1 ]]; then
    BOLD=$(tput bold)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    CYAN=$(tput setaf 6)
    RESET=$(tput sgr0)
else
    BOLD=""; GREEN=""; YELLOW=""; RED=""; CYAN=""; RESET=""
fi

status() { echo "  ${CYAN}$*${RESET}"; }
status_green() { echo "  ${GREEN}$*${RESET}"; }
status_yellow() { echo "  ${YELLOW}$*${RESET}"; }
die() { echo "${RED}Error: $*${RESET}" >&2; exit 1; }

_is_deactivated() {
    local pkg="$1"
    local skip_file="${PENNYKIT_HOME:-$HOME/.pennykit}/configs/extern.skip"
    [[ ! -f "$skip_file" ]] && return 1
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" == "$pkg" ]] && return 0
    done < "$skip_file"
    return 1
}
