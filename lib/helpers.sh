# shellcheck disable=SC1090,SC1091
[[ -v _HELPERS_SH ]] && return || readonly _HELPERS_SH=1

_readlinkf() {
    if command -v greadlink >/dev/null 2>&1; then
        greadlink -f "$@"
    else
        readlink -f "$@"
    fi
}

_curl() {
  curl --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 60 -fL "$@"
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

_verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "  SHA256 mismatch for $file" >&2
        echo "  Expected: $expected" >&2
        echo "  Actual:   $actual" >&2
        return 1
    fi
    echo "  SHA256 verified: $(basename "$file")"
}

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

_mark_problematic() {
    local pkg="$1"
    local problematic_file="${PENNYKIT_HOME:-$HOME/.pennykit}/configs/extern.problematic"
    mkdir -p "$(dirname "$problematic_file")"
    if ! grep -qxF "$pkg" "$problematic_file" 2>/dev/null; then
        echo "$pkg" >> "$problematic_file"
    fi
}

_clear_problematic() {
    local pkg="$1"
    local problematic_file="${PENNYKIT_HOME:-$HOME/.pennykit}/configs/extern.problematic"
    [[ ! -f "$problematic_file" ]] && return
    grep -vxF "$pkg" "$problematic_file" > "$problematic_file.tmp" || true
    mv "$problematic_file.tmp" "$problematic_file" 2>/dev/null || true
    if [[ ! -s "$problematic_file" ]]; then
        rm -f "$problematic_file"
    fi
}
