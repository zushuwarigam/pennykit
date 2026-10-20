#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Miscellaneous commands: update, branch, clean

# ── Self-update ────────────────────────────────────────────────

cmd_update() {
    echo "Updating pennykit..."
    git -C "$PENNYKIT_HOME" pull --rebase
    echo "Done."
}

# ── Branch operations ──────────────────────────────────────────

cmd_branch() {
    if [[ -z "${1:-}" ]]; then
        git -C "$PENNYKIT_HOME" branch
    else
        local branch="$1"
        if [[ ! "$branch" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
            echo "Error: invalid branch name: $branch" >&2
            return 1
        fi
        echo "Switching to branch: $branch"
        git -C "$PENNYKIT_HOME" checkout "$branch"
    fi
}

# ── Clean (remove symlinks pointing to pennykit) ───────────────

cmd_clean() {
    echo "${BOLD}PennyKit clean${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━${RESET}"

    local targets=(
        "$HOME/.config/nvim"
        "$HOME/.tmux.conf"
        "$HOME/.tmux_theme.conf"
    )
    if [[ -f "$HOME/.bashrc" ]]; then
        targets+=("$HOME/.config/bat/config")
        targets+=("$HOME/.config/lazygit/config.yml")
        targets+=("$HOME/.config/lf")
        targets+=("$HOME/.config/yazi")
    fi

    for path in "${targets[@]}"; do
        if [[ -L "$path" ]] && [[ "$(_readlinkf "$path")" == "$PENNYKIT_HOME"* ]]; then
            status "Removing symlink: $path"
            unlink "$path"
        fi
    done

    local nvim_dirs=("$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim")
    for dir in "${nvim_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            status "Removing nvim data: $dir"
            rm -rf "$dir"
        fi
    done

    echo ""
}
