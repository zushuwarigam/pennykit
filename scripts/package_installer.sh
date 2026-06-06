#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"

# Ensure OS detection is loaded
[[ -v PENNYKIT_OS_ID ]] || source "$(dirname "$(readlink -f "$0")")/check_system.sh"

# Load shared helpers (_is_deactivated, _curl, _wget, status, etc.)
source "$PENNYKIT_HOME/lib/helpers.sh" 2>/dev/null || true

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
  _apt_clean()    { echo "  [DRY-RUN] $SUDO apt-get clean"; }
  _brew_clean()   { echo "  [DRY-RUN] brew cleanup --prune=all"; }
else
  _apt_install()  { $SUDO apt-get install -y --no-install-recommends --no-install-suggests "$@" | grep -v "already"; }
  _pipx_install() { pipx install "$@"; }
  _npm_install()  { npm install "$@"; }
  _brew_install() { brew install "$@"; }
  _apt_update()   { $SUDO apt-get update; }
  _apt_clean()    { $SUDO apt-get clean; }
  _brew_clean()   { brew cleanup --prune=all; }
fi

package_sets="${1:-apt}.default"

# Check penny env
echo "Check penny env:"
env | grep PENNY

cd "$PENNYKIT_HOME"

_add_or_skip() {
    local pkg="$1"
    if _is_deactivated "$pkg"; then
        echo "  Skipping $pkg (deactivated)"
        return
    fi
    "add_$pkg"
}

# shellcheck source=./packages/apt.default
source "./packages/${package_sets}"
# shellcheck source=./packages/extern.packages
source "./packages/extern.packages"

# apt
if [[ -v PENNYKIT_APT_DEFAULT ]]; then
  _apt_update && $SUDO apt-get upgrade -y

  _apt_install "${PENNYKIT_APT_DEFAULT[@]}"
  # shellcheck source=./packages/apt.default.postinst
  source "./packages/${package_sets}.postinst"

  [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
    && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _add_or_skip "$p"; done

  case "$PENNYKIT_PACKAGE_SET" in
    ADMIN) # admin package set
      source "./packages/apt.admin"
      [[ -v PENNYKIT_APT_ADMIN ]] \
        && _apt_install "${PENNYKIT_APT_ADMIN[@]}"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.admin"
      [[ -v PENNYKIT_PIPX_ADMIN ]] \
        && _pipx_install "${PENNYKIT_PIPX_ADMIN[@]}"

      source "./packages/npm.admin"
      [[ -v PENNYKIT_NPM_ADMIN ]] \
        && _npm_install "${PENNYKIT_NPM_ADMIN[@]}"

      [[ -v PENNYKIT_EXTERN_ADMIN ]] \
        && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _add_or_skip "$p"; done
      ;;
    DEV) # dev package set
      source "./packages/apt.dev"
      [[ -v PENNYKIT_APT_DEV ]] \
        && _apt_install "${PENNYKIT_APT_DEV[@]}"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.dev"
      [[ -v PENNYKIT_PIPX_DEV ]] \
        && _pipx_install "${PENNYKIT_PIPX_DEV[@]}"

      source "./packages/npm.dev"
      [[ -v PENNYKIT_NPM_DEV ]] \
        && _npm_install "${PENNYKIT_NPM_DEV[@]}"

      [[ -v PENNYKIT_EXTERN_DEV ]] \
        && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _add_or_skip "$p"; done
      ;;
    PENTEST) # pentest package set
      source "./packages/apt.pentest"
      [[ -v PENNYKIT_APT_PENTEST ]] \
        && _apt_install "${PENNYKIT_APT_PENTEST[@]}"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.pentest"
      [[ -v PENNYKIT_PIPX_PENTEST ]] \
        && _pipx_install "${PENNYKIT_PIPX_PENTEST[@]}"

      source "./packages/npm.pentest"
      [[ -v PENNYKIT_NPM_PENTEST ]] \
        && _npm_install "${PENNYKIT_NPM_PENTEST[@]}"

      [[ -v PENNYKIT_EXTERN_PENTEST ]] \
        && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _add_or_skip "$p"; done
      ;;
    ALL) # all package sets
      source "./packages/apt.admin"
      source "./packages/apt.dev"
      source "./packages/apt.pentest"
      PENNYKIT_APT=()
      [[ -v PENNYKIT_APT_ADMIN ]] && PENNYKIT_APT=("${PENNYKIT_APT[@]}" "${PENNYKIT_APT_ADMIN[@]}")
      [[ -v PENNYKIT_APT_DEV ]] && PENNYKIT_APT=("${PENNYKIT_APT[@]}" "${PENNYKIT_APT_DEV[@]}")
      [[ -v PENNYKIT_APT_PENTEST ]] && PENNYKIT_APT=("${PENNYKIT_APT[@]}" "${PENNYKIT_APT_PENTEST[@]}")
      read -ra PENNYKIT_APT_uniq < <(printf '%s\n' "${PENNYKIT_APT[@]}" | sort -u)
      _apt_install "${PENNYKIT_APT_uniq[@]}"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.admin"
      source "./packages/pipx.dev"
      source "./packages/pipx.pentest"
      PENNYKIT_PIPX=()
      [[ -v PENNYKIT_PIPX_ADMIN ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_ADMIN[@]}")
      [[ -v PENNYKIT_PIPX_DEV ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_DEV[@]}")
      [[ -v PENNYKIT_PIPX_PENTEST ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_PENTEST[@]}")
      read -ra PENNYKIT_PIPX_uniq < <(printf '%s\n' "${PENNYKIT_PIPX[@]}" | sort -u)
      _pipx_install "${PENNYKIT_PIPX_uniq[@]}"

      # source "./packages/npm.admin"
      # source "./packages/npm.dev"
      # source "./packages/npm.pentest"
      # PENNYKIT_NPM=()
      # [[ -v PENNYKIT_NPM_ADMIN ]] && PENNYKIT_NPM=("${PENNYKIT_NPM[@]}" "${PENNYKIT_NPM_ADMIN[@]}")
      # [[ -v PENNYKIT_NPM_DEV ]] && PENNYKIT_NPM=("${PENNYKIT_NPM[@]}" "${PENNYKIT_NPM_DEV[@]}")
      # [[ -v PENNYKIT_NPM_PENTEST ]] && PENNYKIT_NPM=("${PENNYKIT_NPM[@]}" "${PENNYKIT_NPM_PENTEST[@]}")
      # PENNYKIT_NPM_uniq=($(printf '%s\n' "${PENNYKIT_NPM[@]}" | sort -u))
      # npm install "${PENNYKIT_NPM_uniq[@]}"

      [[ -v PENNYKIT_EXTERN_ADMIN ]] \
        && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _add_or_skip "$p"; done
      [[ -v PENNYKIT_EXTERN_DEV ]] \
        && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _add_or_skip "$p"; done
      [[ -v PENNYKIT_EXTERN_PENTEST ]] \
        && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _add_or_skip "$p"; done
      ;;
  esac

  _apt_clean
fi

# brew
if [[ -v PENNYKIT_BREW_DEFAULT ]]; then
  _brew_install "${PENNYKIT_BREW_DEFAULT[@]}"
  _brew_clean
fi
