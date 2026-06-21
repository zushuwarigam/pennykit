#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C.UTF-8
export NEEDRESTART_MODE=a

if [[ ! -v PENNYKIT_HOME ]]; then
  export PENNYKIT_HOME
  PENNYKIT_HOME="$HOME/.pennykit"
fi

# Shared helpers (_curl, _wget, status, die, _is_deactivated)
source "$PENNYKIT_HOME/lib/helpers.sh"
printf "### %s\n" "$(_readlinkf "$0")"

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
