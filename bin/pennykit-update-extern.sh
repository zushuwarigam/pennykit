#!/usr/bin/env bash
set -euo pipefail

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [package-set]

Update external packages installed via PennyKit.

Package sets:
  default   Update default external packages
  admin     Update admin external packages
  dev       Update dev external packages
  pentest   Update pentest external packages
  all       Update all external package sets (default)

Options:
  -h, --help  Show this help message and exit

EOF
    exit 0
}

case "${1:-}" in
    -h|--help) usage ;;
esac

package_set="${1:-all}"

function _curl() {
  curl \
    --retry 5 \
    --retry-all-errors \
    --retry-delay 2 \
    --connect-timeout 10 \
    --max-time 60 \
    "$@"
}

function _wget() {
  wget \
    -c \
    --tries=0 \
    --waitretry=15 \
    --timeout=60 \
    --read-timeout=60 \
    "$@"
}

export -f _curl
export -f _wget

PENNYKIT_ON_CONTAINER=false

cd "$PENNYKIT_HOME"

source "./packages/extern.packages"

case "$package_set" in
  default)
    [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
      && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do "update_$p"; done
    ;;
  admin)
    [[ -v PENNYKIT_EXTERN_ADMIN ]] \
      && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do "update_$p"; done
    ;;
  dev)
    [[ -v PENNYKIT_EXTERN_DEV ]] \
      && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do "update_$p"; done
    ;;
  pentest)
    [[ -v PENNYKIT_EXTERN_PENTEST ]] \
      && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do "update_$p"; done
    ;;
  all)
    [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
      && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do "update_$p"; done
    [[ -v PENNYKIT_EXTERN_ADMIN ]] \
      && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do "update_$p"; done
    [[ -v PENNYKIT_EXTERN_DEV ]] \
      && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do "update_$p"; done
    [[ -v PENNYKIT_EXTERN_PENTEST ]] \
      && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do "update_$p"; done
    ;;
  *)
    echo "Error: unknown package set '$package_set'"
    usage
    ;;
esac
