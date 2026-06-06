#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail
[[ -v _CHECK_SYSTEM_SH ]] && return || readonly _CHECK_SYSTEM_SH=1
printf "### %s\n" "$0"

# Defaults
PENNYKIT_OS_VERSION_CODENAME=""
PENNYKIT_OS_ID=""

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    PENNYKIT_OS_ID="macos"
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "$ID" in
      debian|ubuntu)
        PENNYKIT_OS_ID=$ID
        PENNYKIT_OS_VERSION_CODENAME=$VERSION_CODENAME
        ;;
      *)
        if [[ "${ID_LIKE:-}" == *debian* ]]; then
          PENNYKIT_OS_ID=debian
          PENNYKIT_OS_VERSION_CODENAME=$VERSION_CODENAME
        else
          PENNYKIT_OS_ID=other
        fi
        ;;
    esac
  else
    PENNYKIT_OS_ID=other
  fi
}

detect_os

export PENNYKIT_OS_ID
export PENNYKIT_OS_VERSION_CODENAME

echo "PENNYKIT_OS_ID: $PENNYKIT_OS_ID"
echo "PENNYKIT_OS_VERSION_CODENAME: $PENNYKIT_OS_VERSION_CODENAME"
