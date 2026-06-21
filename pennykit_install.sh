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

# Ensure npm global prefix is user-local (avoids EACCES on npm install -g)
mkdir -p "${HOME}/.npm-global"
npm config set prefix "${HOME}/.npm-global"

# Rootless mode: skip apt, install extern packages to ~/.local/
PENNYKIT_LOCAL_DIR="${PENNYKIT_LOCAL_DIR:-$HOME/.local}"
if [[ -n "${PENNYKIT_ROOTLESS:-}" ]]; then
  echo "  [ROOTLESS] Rootless mode enabled"
  export PENNYKIT_ROOTLESS
  export PENNYKIT_LOCAL_DIR
  mkdir -p "$PENNYKIT_LOCAL_DIR/bin" "$PENNYKIT_LOCAL_DIR/opt" "$PENNYKIT_LOCAL_DIR/go"
fi

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
