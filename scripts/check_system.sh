#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

# Defaults
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

export PENNYKIT_ON_CONTAINER
export PENNYKIT_OS_ID
export PENNYKIT_OS_VERSION_CODENAME

echo "PENNYKIT_ON_CONTAINER: $PENNYKIT_ON_CONTAINER"
echo "PENNYKIT_OS_ID: $PENNYKIT_OS_ID"
echo "PENNYKIT_OS_VERSION_CODENAME: $PENNYKIT_OS_VERSION_CODENAME"
