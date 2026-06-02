#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8

export PENNYKIT_OS_ID
export PENNYKIT_OS_VERSION_CODENAME

# Enable alias expansion in scripts
# shopt -s expand_aliases
# alias _curl="curl --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 60"
# alias _wget="wget -c --tries=0 --waitretry=15 --timeout=60 --read-timeout=60"

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

if [[ ! -v PENNYKIT_HOME ]]; then
  export PENNYKIT_HOME
  PENNYKIT_HOME="$HOME/.pennykit"
fi

# Detect OS and container
source "$PENNYKIT_HOME/scripts/check_system.sh"

cd "$PENNYKIT_HOME"

# Packages
case "$PENNYKIT_OS_ID" in
  "debian")
    ./scripts/package_installer.sh apt
    ;;
  "macos")
    ./scripts/package_installer.sh brew
    ;;
  *) echo "Skipping other os..." && exit 1 ;;
esac

# Config package
source ./scripts/package_configure.sh
