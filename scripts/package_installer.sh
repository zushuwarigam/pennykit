#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

if [[ $(id -u) != 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

package_sets="${1:-apt}.default"

# Check penny env
echo "Check penny env:"
env | grep PENNY
sleep 2

cd "$PENNYKIT_HOME"

_is_deactivated() {
    local pkg="$1"
    local skip_file="$PENNYKIT_HOME/configs/extern.skip"
    [[ ! -f "$skip_file" ]] && return 1
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        [[ "$line" == "$pkg" ]] && return 0
    done < "$skip_file"
    return 1
}

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
  $SUDO apt-get update && $SUDO apt-get upgrade -y

  # Install defaults
  $SUDO apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    "${PENNYKIT_APT_DEFAULT[@]}" | grep -v "already"
  # shellcheck source=./packages/apt.default.postinst
  source "./packages/${package_sets}.postinst"

  [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
    && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _add_or_skip "$p"; done

  case "$PENNYKIT_PACKAGE_SET" in
    ADMIN) # admin package set
      source "./packages/apt.admin"
      [[ -v PENNYKIT_APT_ADMIN ]] \
        && $SUDO apt-get install -y \
        --no-install-recommends \
        --no-install-suggests \
        "${PENNYKIT_APT_ADMIN[@]}" | grep -v "already"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.admin"
      [[ -v PENNYKIT_PIPX_ADMIN ]] \
        && pipx install "${PENNYKIT_PIPX_ADMIN[@]}"

      source "./packages/npm.admin"
      [[ -v PENNYKIT_NPM_ADMIN ]] \
        && npm install "${PENNYKIT_NPM_ADMIN[@]}"

      [[ -v PENNYKIT_EXTERN_ADMIN ]] \
        && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _add_or_skip "$p"; done
      ;;
    DEV) # dev package set
      source "./packages/apt.dev"
      [[ -v PENNYKIT_APT_DEV ]] \
        && $SUDO apt-get install -y \
        --no-install-recommends \
        --no-install-suggests \
        "${PENNYKIT_APT_DEV[@]}" | grep -v "already"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.dev"
      [[ -v PENNYKIT_PIPX_DEV ]] \
        && pipx install "${PENNYKIT_PIPX_DEV[@]}"

      source "./packages/npm.dev"
      [[ -v PENNYKIT_NPM_DEV ]] \
        && npm install "${PENNYKIT_NPM_DEV[@]}"

      [[ -v PENNYKIT_EXTERN_DEV ]] \
        && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _add_or_skip "$p"; done
      ;;
    PENTEST) # pentest package set
      source "./packages/apt.pentest"
      [[ -v PENNYKIT_APT_PENTEST ]] \
        && $SUDO apt-get install -y \
        --no-install-recommends \
        --no-install-suggests \
        "${PENNYKIT_APT_PENTEST[@]}" | grep -v "already"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.pentest"
      [[ -v PENNYKIT_PIPX_PENTEST ]] \
        && pipx install "${PENNYKIT_PIPX_PENTEST[@]}"

      source "./packages/npm.pentest"
      [[ -v PENNYKIT_NPM_PENTEST ]] \
        && npm install "${PENNYKIT_NPM_PENTEST[@]}"

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
      PENNYKIT_APT_uniq=($(printf '%s\n' "${PENNYKIT_APT[@]}" | sort -u))
      $SUDO apt-get install -y \
        --no-install-recommends \
        --no-install-suggests \
        "${PENNYKIT_APT_uniq[@]}" | grep -v "already"
      # shellcheck source=./packages/apt.default.postinst
      source "./packages/${package_sets}.postinst"

      source "./packages/pipx.admin"
      source "./packages/pipx.dev"
      source "./packages/pipx.pentest"
      PENNYKIT_PIPX=()
      [[ -v PENNYKIT_PIPX_ADMIN ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_ADMIN[@]}")
      [[ -v PENNYKIT_PIPX_DEV ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_DEV[@]}")
      [[ -v PENNYKIT_PIPX_PENTEST ]] && PENNYKIT_PIPX=("${PENNYKIT_PIPX[@]}" "${PENNYKIT_PIPX_PENTEST[@]}")
      PENNYKIT_PIPX_uniq=($(printf '%s\n' "${PENNYKIT_PIPX[@]}" | sort -u))
      pipx install "${PENNYKIT_PIPX_uniq[@]}"

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

  $SUDO apt-get clean
fi

# brew
if [[ -v PENNYKIT_BREW_DEFAULT ]]; then
  brew install "${PENNYKIT_BREW_DEFAULT[@]}"
  brew cleanup --prune=all
fi
