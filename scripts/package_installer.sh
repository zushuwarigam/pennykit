#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"

# Load shared helpers (_readlinkf, _is_deactivated, _curl, _wget, status, etc.)
source "$PENNYKIT_HOME/lib/helpers.sh" 2>/dev/null || true
printf "### %s\n" "$(_readlinkf "$0")" 2>/dev/null || printf "### %s\n" "$0"

# Ensure OS detection is loaded
[[ -v PENNYKIT_OS_ID ]] || source "$(dirname "$(_readlinkf "$0")")/check_system.sh"

if [[ $(id -u) != 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# Dry-run mode: set PENNYKIT_DRY_RUN=1 to print commands without executing
if [[ -n "${PENNYKIT_DRY_RUN:-}" ]]; then
  echo "  [DRY-RUN] Dry-run mode enabled — install commands will be printed, not executed"
  _apt_install() { echo "  [DRY-RUN] $SUDO apt-get install -y $*"; }
  _pipx_install() { echo "  [DRY-RUN] pipx install $*"; }
  _npm_install()  { echo "  [DRY-RUN] npm install $*"; }
  _brew_install() { echo "  [DRY-RUN] brew install $*"; }
  _apt_update()   { echo "  [DRY-RUN] $SUDO apt-get update"; }
  _apt_upgrade()  { echo "  [DRY-RUN] $SUDO apt-get upgrade -y"; }
  _apt_clean()    { echo "  [DRY-RUN] $SUDO apt-get clean"; }
  _brew_clean()   { echo "  [DRY-RUN] brew cleanup --prune=all"; }
else
  _apt_install()  { $SUDO apt-get install -y --no-install-recommends --no-install-suggests "$@" | grep -v "already"; }
  _pipx_install() { pipx install "$@"; }
  _npm_install()  { npm install "$@"; }
  _brew_install() { brew install "$@"; }
  _apt_update()   { $SUDO apt-get update; }
  _apt_upgrade()  { $SUDO apt-get upgrade -y; }
  _apt_clean()    { $SUDO apt-get clean; }
  _brew_clean()   { brew cleanup --prune=all; }
fi

cd "$PENNYKIT_HOME"

_add_or_skip() {
    local pkg="$1"
    if _is_deactivated "$pkg"; then
        echo "  Skipping $pkg (deactivated)"
        return
    fi
    "add_$pkg"
}

# --- Pyramid layer stack ---
# DEFAULT: only base    ADMIN: base → admin
# DEV: base → dev       PENTEST: base → dev → pentest
# ALL: base → admin → dev → pentest
layers=()
case "${PENNYKIT_PACKAGE_SET:-DEFAULT}" in
  ADMIN)   layers=(admin) ;;
  DEV)     layers=(dev) ;;
  PENTEST) layers=(dev pentest) ;;
  ALL)     layers=(admin dev pentest) ;;
esac

# shellcheck source=./packages/apt.default
source "./packages/apt.default"
# shellcheck source=./packages/npm.default
source "./packages/npm.default" 2>/dev/null || true
# shellcheck source=./packages/extern.packages
source "./packages/extern.packages"

# apt
if [[ -v PENNYKIT_APT_DEFAULT ]]; then
  _apt_update && _apt_upgrade

  _apt_install "${PENNYKIT_APT_DEFAULT[@]}"
  # shellcheck source=./packages/apt.default.postinst
  source "./packages/apt.default.postinst"

  [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
    && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _add_or_skip "$p"; done

  declare -A _seen_apt
  declare -a _apt_pkgs=()
  for layer in "${layers[@]}"; do
    # Each source may define PENNYKIT_APT_<LAYER> and/or other variables.
    # These variables persist for the loop duration; _seen_apt prevents duplicates.
    source "./packages/apt.${layer}" 2>/dev/null || true

    local_arr="PENNYKIT_APT_${layer^^}[@]"
    for pkg in "${!local_arr}"; do
      if [[ -z "${_seen_apt[$pkg]-}" ]]; then
        _seen_apt[$pkg]=1
        _apt_pkgs+=("$pkg")
      fi
    done
  done
  [[ ${#_apt_pkgs[@]} -gt 0 ]] && _apt_install "${_apt_pkgs[@]}"

  # pipx
  declare -A _seen_pipx
  declare -a _pipx_pkgs=()
  for layer in "${layers[@]}"; do
    source "./packages/pipx.${layer}" 2>/dev/null || true

    local_arr="PENNYKIT_PIPX_${layer^^}[@]"
    for pkg in "${!local_arr}"; do
      if [[ -z "${_seen_pipx[$pkg]-}" ]]; then
        _seen_pipx[$pkg]=1
        _pipx_pkgs+=("$pkg")
      fi
    done
  done
  [[ ${#_pipx_pkgs[@]} -gt 0 ]] && _pipx_install "${_pipx_pkgs[@]}"

  # npm
  declare -A _seen_npm
  declare -a _npm_pkgs=()

  if [[ -v PENNYKIT_NPM_DEFAULT ]] && [[ ${#PENNYKIT_NPM_DEFAULT[@]} -gt 0 ]]; then
    npm install -g "${PENNYKIT_NPM_DEFAULT[@]}"
  fi

  for layer in "${layers[@]}"; do
    source "./packages/npm.${layer}" 2>/dev/null || true

    local_arr="PENNYKIT_NPM_${layer^^}[@]"
    for pkg in "${!local_arr}"; do
      if [[ -z "${_seen_npm[$pkg]-}" ]]; then
        _seen_npm[$pkg]=1
        _npm_pkgs+=("$pkg")
      fi
    done
  done
  [[ ${#_npm_pkgs[@]} -gt 0 ]] && _npm_install "${_npm_pkgs[@]}"

  # extern
  for layer in "${layers[@]}"; do
    local_arr="PENNYKIT_EXTERN_${layer^^}[@]"
    [[ -v "PENNYKIT_EXTERN_${layer^^}" ]] \
      && for p in "${!local_arr}"; do _add_or_skip "$p"; done
  done

  _apt_clean
fi

# brew
if [[ -v PENNYKIT_BREW_DEFAULT ]]; then
  _brew_install "${PENNYKIT_BREW_DEFAULT[@]}"
  _brew_clean
fi
