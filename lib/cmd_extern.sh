#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Extern package management command

_update_or_skip() {
    local pkg="$1"
    if _is_deactivated "$pkg"; then
        echo "  Skipping $pkg (deactivated)"
        return
    fi
    if command -v "$pkg" >/dev/null 2>&1; then
        if declare -F "update_$pkg" >/dev/null 2>&1; then
            if "update_$pkg"; then
                _clear_problematic "$pkg"
            else
                echo "  ${YELLOW}⚠ ${pkg}: update failed, marked as problematic${RESET}"
                _mark_problematic "$pkg"
            fi
        else
            echo "  $pkg: already installed, no update function"
            _clear_problematic "$pkg"
        fi
    else
        echo "  $pkg: not installed, trying add_${pkg}..."
        if "add_$pkg"; then
            _clear_problematic "$pkg"
        else
            echo "  ${YELLOW}⚠ ${pkg}: install failed, marked as problematic${RESET}"
            _mark_problematic "$pkg"
        fi
    fi
}

cmd_extern() {
    cd "$PENNYKIT_HOME"
    local skip_file="configs/extern.skip"
    local problematic_file="configs/extern.problematic"
    local cmd="${1:-}"
    local set="${cmd:-default}"

    case "$cmd" in
        deactivate)
            [[ -z "${2:-}" ]] && { echo "Usage: $(basename "$0") extern deactivate <package>"; exit 1; }
            if ! grep -qxF "$2" "$skip_file" 2>/dev/null; then
                echo "$2" >> "$skip_file"
                echo "Deactivated: $2"
            else
                echo "Already deactivated: $2"
            fi
            return
            ;;
        activate)
            [[ -z "${2:-}" ]] && { echo "Usage: $(basename "$0") extern activate <package>"; exit 1; }
            if [[ -f "$skip_file" ]]; then
                grep -vxF "$2" "$skip_file" > "$skip_file.tmp" || true
                mv "$skip_file.tmp" "$skip_file" 2>/dev/null || true
                [[ ! -s "$skip_file" ]] && rm -f "$skip_file"
                echo "Activated: $2"
            fi
            return
            ;;
        list-deactivated)
            if [[ -f "$skip_file" ]]; then
                echo "Deactivated packages:"
                grep -v '^#' "$skip_file"
            else
                echo "No deactivated packages."
            fi
            return
            ;;
        list-problematic)
            if [[ -f "$problematic_file" ]]; then
                local count
                count=$(grep -cvE '^\s*(#|$)' "$problematic_file" || true)
                if [[ "$count" -gt 0 ]]; then
                    echo "Problematic packages:"
                    grep -vE '^\s*(#|$)' "$problematic_file"
                else
                    echo "No problematic packages."
                fi
            else
                echo "No problematic packages."
            fi
            return
            ;;
        reset-problematic)
            if [[ -f "$problematic_file" ]]; then
                rm -f "$problematic_file"
                echo "Problematic list cleared."
            else
                echo "No problematic packages to clear."
            fi
            return
            ;;
    esac

    # shellcheck source=./scripts/install/check_system.sh
    source "$PENNYKIT_HOME/scripts/install/check_system.sh" 2>/dev/null || true
    # shellcheck source=./packages/extern.packages
    source "./packages/extern.packages"

    # Retry previously problematic packages before processing the requested set
    if [[ -f "$problematic_file" ]]; then
        echo "  Retrying problematic packages..."
        local temp_file="${problematic_file}.tmp"
        : > "$temp_file"
        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            if command -v "$line" >/dev/null 2>&1; then
                echo "  ${GREEN}✓${RESET} $line: already installed, removing from problematic list"
            else
                echo "  $line: retrying add_${line}..."
                if "add_$line"; then
                    echo "  ${GREEN}✓${RESET} $line: install succeeded"
                else
                    echo "  ${YELLOW}⚠ ${line}: retry failed${RESET}"
                    echo "$line" >> "$temp_file"
                fi
            fi
        done < "$problematic_file"
        mv "$temp_file" "$problematic_file" 2>/dev/null || true
        [[ ! -s "$problematic_file" ]] && rm -f "$problematic_file"
    fi

    case "$set" in
        default)
            [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
                && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _update_or_skip "$p"; done
            ;;
        admin)
            [[ -v PENNYKIT_EXTERN_ADMIN ]] \
                && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _update_or_skip "$p"; done
            ;;
        dev)
            [[ -v PENNYKIT_EXTERN_DEV ]] \
                && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _update_or_skip "$p"; done
            ;;
        pentest)
            [[ -v PENNYKIT_EXTERN_PENTEST ]] \
                && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _update_or_skip "$p"; done
            ;;
        all)
            [[ -v PENNYKIT_EXTERN_DEFAULT ]] \
                && for p in "${PENNYKIT_EXTERN_DEFAULT[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_ADMIN ]] \
                && for p in "${PENNYKIT_EXTERN_ADMIN[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_DEV ]] \
                && for p in "${PENNYKIT_EXTERN_DEV[@]}"; do _update_or_skip "$p"; done
            [[ -v PENNYKIT_EXTERN_PENTEST ]] \
                && for p in "${PENNYKIT_EXTERN_PENTEST[@]}"; do _update_or_skip "$p"; done
            ;;
        *)
            echo "Usage: $(basename "$0") extern [default|admin|dev|pentest|all|deactivate|activate|list-deactivated|list-problematic|reset-problematic]"
            exit 1
            ;;
    esac
}
