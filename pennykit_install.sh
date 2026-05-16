#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8

export PENNYKIT_ON_CONTAINER
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

PENNYKIT_OS_VERSION_CODENAME=""
PENNYKIT_OS_ID=""
PENNYKIT_ON_CONTAINER=false

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    PENNYKIT_OS_ID="macos"
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "$ID" in
      debian)
        PENNYKIT_OS_ID=debian
        PENNYKIT_OS_VERSION_CODENAME=$VERSION_CODENAME
        ;;
      *)
        PENNYKIT_OS_ID=other
        ;;
    esac
  else
    PENNYKIT_OS_ID=other
  fi
}

running_in_docker() {
  if [ -f /.dockerenv ] && [ "$(cat /proc/1/comm 2>/dev/null)" = "sh" ]; then
    PENNYKIT_ON_CONTAINER=true
    return
  fi

  if [ -f /proc/1/cgroup ] && grep -q 'docker' /proc/1/cgroup; then
    PENNYKIT_ON_CONTAINER=true
    return
  fi

  PENNYKIT_ON_CONTAINER=false
}

running_in_docker
detect_os

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
