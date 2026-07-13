load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/{configs/{bat,tmux,lf,yazi,lazygit,editorconfig,wezterm},lib}
    mkdir -p "$HOME/.config"

    cp "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh" "$PENNYKIT_HOME/lib/helpers.sh"
}

# Helper: source a config file
source_config() {
    local name="$1"
    bash -c "
    export PENNYKIT_HOME='$PENNYKIT_HOME'
    export HOME='$HOME'
    source '$PENNYKIT_HOME/lib/helpers.sh'
    source '$(dirname "$BATS_TEST_FILENAME")/../../configs/config.$name'
    "
}

# ── config.bat ──────────────────────────────────────────────────

@test "config.bat: creates symlink when missing" {
    run source_config bat
    assert_success
    [[ -L "$HOME/.config/bat" ]]
    run readlink -f "$HOME/.config/bat"
    assert_output --partial "configs/bat"
}

@test "config.bat: idempotent on existing symlink" {
    source_config bat
    run source_config bat
    assert_success
    [[ -L "$HOME/.config/bat" ]]
}

@test "config.bat: skips when directory already exists" {
    mkdir -p "$HOME/.config/bat"
    run source_config bat
    assert_success
    [[ -d "$HOME/.config/bat" ]]
    [[ ! -L "$HOME/.config/bat" ]]
}

# ── config.tmux ─────────────────────────────────────────────────

@test "config.tmux: creates tmux.conf and tmux_theme.conf" {
    run source_config tmux
    assert_success
    [[ -L "$HOME/.tmux.conf" ]]
    [[ -L "$HOME/.tmux_theme.conf" ]]
}

@test "config.tmux: unlinks existing symlink" {
    ln -s "$BATS_TEST_TMPDIR/old" "$HOME/.tmux.conf"
    ln -s "$BATS_TEST_TMPDIR/old_theme" "$HOME/.tmux_theme.conf"
    run source_config tmux
    assert_success
    [[ -L "$HOME/.tmux.conf" ]]
    run readlink -f "$HOME/.tmux.conf"
    assert_output --partial "configs/tmux/tmux.conf"
}

@test "config.tmux: backs up existing regular file" {
    echo "old config" > "$HOME/.tmux.conf"
    echo "old theme" > "$HOME/.tmux_theme.conf"
    run source_config tmux
    assert_success
    [[ -L "$HOME/.tmux.conf" ]]
    run find "$HOME" -name ".tmux.conf_*" -type f
    assert_success
    assert_output --partial ".tmux.conf_"
}

@test "config.tmux: idempotent on re-run" {
    source_config tmux
    run source_config tmux
    assert_success
    [[ -L "$HOME/.tmux.conf" ]]
}

# ── config.lf ───────────────────────────────────────────────────

@test "config.lf: creates symlink when missing" {
    run source_config lf
    assert_success
    [[ -L "$HOME/.config/lf" ]]
}

@test "config.lf: idempotent on existing symlink" {
    source_config lf
    run source_config lf
    assert_success
    [[ -L "$HOME/.config/lf" ]]
}

@test "config.lf: skips when directory exists" {
    mkdir -p "$HOME/.config/lf"
    run source_config lf
    assert_success
    [[ -d "$HOME/.config/lf" ]]
}

# ── config.lazygit ──────────────────────────────────────────────

@test "config.lazygit: creates symlink when missing" {
    run source_config lazygit
    assert_success
    [[ -L "$HOME/.config/lazygit" ]]
}

@test "config.lazygit: idempotent on re-run" {
    source_config lazygit
    run source_config lazygit
    assert_success
    [[ -L "$HOME/.config/lazygit" ]]
}

# ── config.editorconfig ─────────────────────────────────────────

@test "config.editorconfig: creates symlink" {
    run source_config editorconfig
    assert_success
    [[ -L "$HOME/.editorconfig" ]]
}

@test "config.editorconfig: unlinks existing symlink" {
    ln -s "$BATS_TEST_TMPDIR/old" "$HOME/.editorconfig"
    run source_config editorconfig
    assert_success
    run readlink -f "$HOME/.editorconfig"
    assert_output --partial "configs/editorconfig"
}

@test "config.editorconfig: backs up existing regular file" {
    echo "old config" > "$HOME/.editorconfig"
    run source_config editorconfig
    assert_success
    [[ -L "$HOME/.editorconfig" ]]
    run find "$HOME" -name ".editorconfig_*" -type f
    assert_success
    assert_output --partial ".editorconfig_"
}

# ── config.wezterm ──────────────────────────────────────────────

@test "config.wezterm: creates symlink when wezterm exists" {
    local stub_dir="$BATS_TEST_TMPDIR/stub_bin"
    mkdir -p "$stub_dir"
    echo '#!/bin/bash' > "$stub_dir/wezterm"
    chmod +x "$stub_dir/wezterm"
    PATH="$stub_dir:$PATH" run source_config wezterm
    assert_success
    [[ -L "$HOME/.wezterm.lua" ]]
}

@test "config.wezterm: skips when wezterm not present" {
    run source_config wezterm
    assert_success
    [[ ! -e "$HOME/.wezterm.lua" ]]
}

@test "config.wezterm: skips when wezterm.lua already exists" {
    local stub_dir="$BATS_TEST_TMPDIR/stub_bin"
    mkdir -p "$stub_dir"
    echo '#!/bin/bash' > "$stub_dir/wezterm"
    chmod +x "$stub_dir/wezterm"
    echo "existing config" > "$HOME/.wezterm.lua"
    PATH="$stub_dir:$PATH" run source_config wezterm
    assert_success
    [[ -f "$HOME/.wezterm.lua" ]]
    [[ ! -L "$HOME/.wezterm.lua" ]]
}

# ── config.fzf ──────────────────────────────────────────────────

@test "config.fzf: evals fzf --bash when in bash" {
    local stub_dir="$BATS_TEST_TMPDIR/stub_bin"
    mkdir -p "$stub_dir"
    echo '#!/bin/bash' > "$stub_dir/fzf"
    echo 'echo "fzf --bash called"' >> "$stub_dir/fzf"
    chmod +x "$stub_dir/fzf"
    PATH="$stub_dir:$PATH" run bash -c "
    export PENNYKIT_HOME='$PENNYKIT_HOME'
    export HOME='$HOME'
    export SHELL=/bin/bash
    source '$(dirname "$BATS_TEST_FILENAME")/../../configs/config.fzf'
    "
    assert_success
    assert_output --partial "fzf --bash called"
}

@test "config.fzf: skips when fzf not present" {
    run source_config fzf
    assert_success
}

# ── config.yazi ─────────────────────────────────────────────────

@test "config.yazi: creates symlink when missing" {
    run source_config yazi
    assert_success
    [[ -L "$HOME/.config/yazi" ]]
}

@test "config.yazi: idempotent on existing symlink" {
    source_config yazi
    run source_config yazi
    assert_success
}

@test "config.yazi: skips when directory exists" {
    mkdir -p "$HOME/.config/yazi"
    run source_config yazi
    assert_success
    [[ -d "$HOME/.config/yazi" ]]
}

# ── config.shell (zsh) ──────────────────────────────────────────

# Helper to run config.shell with ZSH set (skips oh-my-zsh install)
source_config_shell_zsh() {
    bash -c "
    export PENNYKIT_HOME='$PENNYKIT_HOME'
    export HOME='$HOME'
    export ZSH='$HOME/.oh-my-zsh'
    source '$PENNYKIT_HOME/lib/helpers.sh'
    source '$(dirname "$BATS_TEST_FILENAME")/../../configs/config.shell'
    "
}

@test "config.shell: updates old pennykit.zsh path in .zshrc" {
    cat > "$HOME/.zshrc" << 'ZSHRC'
[[ -f ~/.pennykit/pennykit.zsh ]] && source ${HOME}/.pennykit/pennykit.zsh
ZSHRC
    run source_config_shell_zsh
    assert_success
    grep -q '~/.pennykit/shell/pennykit.zsh' "$HOME/.zshrc"
}

@test "config.shell: adds pennykit.zsh source line when missing" {
    cat > "$HOME/.zshrc" << 'ZSHRC'
# empty zshrc
ZSHRC
    run source_config_shell_zsh
    assert_success
    grep -q 'source.*pennykit' "$HOME/.zshrc"
}

@test "config.shell: does not duplicate pennykit.zsh source line" {
    cat > "$HOME/.zshrc" << 'ZSHRC'
[[ -f ~/.pennykit/shell/pennykit.zsh ]] && source ${HOME}/.pennykit/shell/pennykit.zsh
ZSHRC
    run source_config_shell_zsh
    assert_success
    local count
    count=$(grep -c 'source.*pennykit' "$HOME/.zshrc")
    [[ "$count" == "1" ]]
}

@test "config.shell: creates .zshrc and adds source line when missing" {
    # Ensure no .zshrc exists
    rm -f "$HOME/.zshrc"
    run source_config_shell_zsh
    assert_success
    [[ -f "$HOME/.zshrc" ]]
    grep -q 'source.*pennykit' "$HOME/.zshrc"
}
