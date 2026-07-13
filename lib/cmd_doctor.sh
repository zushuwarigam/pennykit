#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Health checks command

cmd_doctor() {
    echo "${BOLD}PennyKit doctor${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━${RESET}"
    local errors=0 warnings=0

    # Repo check
    if git -C "$PENNYKIT_HOME" rev-parse --git-dir >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} Repository: valid"
    else
        echo "  ${RED}✗${RESET} Repository: not a git repo"
        ((++errors))
    fi

    # Symlinks
    local symlinks=(
        "Neovim:$HOME/.config/nvim"
        "tmux:$HOME/.tmux.conf"
        "tmux theme:$HOME/.tmux_theme.conf"
    )
    if [[ -f "$HOME/.bashrc" ]]; then
        symlinks+=("bat:$HOME/.config/bat/config")
        symlinks+=("lazygit:$HOME/.config/lazygit/config.yml")
        symlinks+=("lf:$HOME/.config/lf")
        symlinks+=("yazi:$HOME/.config/yazi")
    fi
    for entry in "${symlinks[@]}"; do
        local label="${entry%%:*}"
        local path="${entry#*:}"
        if [[ -e "$path" ]]; then
            echo "  ${GREEN}✓${RESET} Symlink: $label"
        else
            echo "  ${YELLOW}⚠${RESET} Symlink: $label (not found)"
            ((++warnings))
        fi
    done

    # Required binaries
    local binaries=("nvim" "git" "rg" "fzf" "tmux" "lazygit" "bat" "lf" "fd" "jq" "zoxide")
    # Debian/Ubuntu renames: some upstream binaries have different names
    local -A bin_fallback
    bin_fallback["bat"]="batcat"
    bin_fallback["fd"]="fdfind"
    for bin in "${binaries[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            echo "  ${GREEN}✓${RESET} Binary: $bin"
        elif [[ -n "${bin_fallback[$bin]:-}" ]] && command -v "${bin_fallback[$bin]}" >/dev/null 2>&1; then
            echo "  ${GREEN}✓${RESET} Binary: $bin (as ${bin_fallback[$bin]})"
        else
            echo "  ${YELLOW}⚠${RESET} Binary: $bin (not found)"
            ((++warnings))
        fi
    done

    # Theme
    if [[ -f "$PENNYKIT_HOME/configs/theme.conf" ]]; then
        local active
        active=$(grep '^PENNYKIT_THEME=' "$PENNYKIT_HOME/configs/theme.conf" 2>/dev/null | cut -d= -f2 | tr -d '"')
        if [[ -f "$PENNYKIT_HOME/configs/themes/${active}.conf" ]]; then
            echo "  ${GREEN}✓${RESET} Theme: $active"
        else
            echo "  ${RED}✗${RESET} Theme: $active config missing"
            ((++errors))
        fi
    else
        echo "  ${YELLOW}⚠${RESET} Theme: not configured"
        ((++warnings))
    fi

    # Nerd Font
    if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "nerd font" 2>/dev/null; then
        echo "  ${GREEN}✓${RESET} Nerd Font: found"
    else
        echo "  ${YELLOW}⚠${RESET} Nerd Font: not detected (icons may not render)"
        ((++warnings))
    fi

    # EditorConfig
    if [[ -f "$PENNYKIT_HOME/configs/editorconfig/editorconfig" ]]; then
        echo "  ${GREEN}✓${RESET} EditorConfig: present"
    fi

    # External packages check
    if [[ -f "$PENNYKIT_HOME/configs/extern.problematic" ]]; then
        local problematic_count
        problematic_count=$(wc -l < "$PENNYKIT_HOME/configs/extern.problematic")
        if [[ "$problematic_count" -gt 0 ]]; then
            echo "  ${YELLOW}⚠${RESET} External packages: $problematic_count problematic"
            ((++warnings))
        fi
    fi

    # Docker check
    if command -v docker >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} Docker: available"
    else
        echo "  ${YELLOW}⚠${RESET} Docker: not found (optional)"
        ((++warnings))
    fi

    # Python check
    if command -v python3 >/dev/null 2>&1; then
        local py_version
        py_version=$(python3 --version 2>&1 | awk '{print $2}')
        echo "  ${GREEN}✓${RESET} Python: $py_version"
    else
        echo "  ${YELLOW}⚠${RESET} Python: not found (needed for theme apply)"
        ((++warnings))
    fi

    echo ""
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        echo "  ${GREEN}All checks passed.${RESET}"
    elif [[ $errors -eq 0 ]]; then
        echo "  ${YELLOW}$warnings warnings, no errors.${RESET}"
    else
        echo "  ${RED}$errors errors, $warnings warnings.${RESET}"
    fi
    echo ""
}
