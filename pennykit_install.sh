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

# Install NVM and latest Node.js if not already present
NVM_DIR="${HOME}/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
fi

# Source NVM and install latest Node.js
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
if command -v nvm &>/dev/null; then
  # Remove conflicting npm prefix if NVM is managing Node
  npm config delete prefix 2>/dev/null || true
  if [[ "$(nvm current 2>/dev/null)" == "system" ]] || ! nvm ls &>/dev/null 2>&1; then
    echo "Installing latest Node.js via NVM..."
    nvm install node
    nvm alias default node
  else
    echo "Node.js already installed: $(nvm current)"
  fi
else
  echo "WARNING: NVM not available, skipping Node.js install"
  # Fall back to npm prefix if no NVM
  mkdir -p "${HOME}/.npm-global"
  npm config set prefix "${HOME}/.npm-global"
fi

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
