load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/{configs,lib,nvim-starter/astronvim_v6,nvim-starter/lazyvim}
    mkdir -p "$HOME"/.config

    cp "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh" "$PENNYKIT_HOME/lib/helpers.sh"
    cp "$(dirname "$BATS_TEST_FILENAME")/../../configs/config.nvim" "$PENNYKIT_HOME/configs/config.nvim"

    CONFIGURE="$PENNYKIT_HOME/../scripts/install/package_configure.sh"
    if [[ ! -f "$CONFIGURE" ]]; then
        CONFIGURE="$(dirname "$BATS_TEST_FILENAME")/../../scripts/install/package_configure.sh"
    fi
}

@test "package_configure: sources each config file" {
    cat > "$PENNYKIT_HOME/configs/config.test" << 'SCRIPT'
# shellcheck disable=all
printf "sourced: config.test\n"
SCRIPT

    run bash "$CONFIGURE"
    assert_success
    assert_output --partial "sourced: config.test"
}

@test "package_configure: sources multiple config files" {
    cat > "$PENNYKIT_HOME/configs/config.one" << 'SCRIPT'
# shellcheck disable=all
printf "sourced: config.one\n"
SCRIPT
    cat > "$PENNYKIT_HOME/configs/config.two" << 'SCRIPT'
# shellcheck disable=all
printf "sourced: config.two\n"
SCRIPT

    run bash "$CONFIGURE"
    assert_success
    assert_output --partial "sourced: config.one"
    assert_output --partial "sourced: config.two"
}

@test "package_configure: fails gracefully when configs directory missing" {
    rm -rf "$PENNYKIT_HOME/configs"
    run bash "$CONFIGURE"
    assert_failure
    assert_output --partial "No such file or directory"
}

@test "package_configure: runs without errors when helpers.sh is missing" {
    rm -f "$PENNYKIT_HOME/lib/helpers.sh"
    run bash "$CONFIGURE"
    assert_success
}

# ── config.nvim ─────────────────────────────────────────────────

@test "config.nvim: creates symlink for default astronvim_v6" {
    run bash "$CONFIGURE"
    assert_success
    [[ -L "$HOME/.config/nvim" ]]
    run readlink -f "$HOME/.config/nvim"
    assert_output --partial "astronvim_v6"
}

@test "config.nvim: creates symlink for custom config" {
    export PENNYKIT_NVIM_CONFIG="lazyvim"
    run bash "$CONFIGURE"
    assert_success
    run readlink -f "$HOME/.config/nvim"
    assert_output --partial "lazyvim"
}

@test "config.nvim: idempotent on existing correct symlink" {
    run bash "$CONFIGURE"
    assert_success
    local before
    before=$(readlink -f "$HOME/.config/nvim")

    run bash "$CONFIGURE"
    assert_success
    local after
    after=$(readlink -f "$HOME/.config/nvim")
    [[ "$before" == "$after" ]]
}

@test "config.nvim: with force replaces external symlink" {
    mkdir -p "$BATS_TEST_TMPDIR/external-nvim"
    ln -s "$BATS_TEST_TMPDIR/external-nvim" "$HOME/.config/nvim"

    export PENNYKIT_FORCE="true"
    run bash "$CONFIGURE"
    assert_success
    run readlink -f "$HOME/.config/nvim"
    assert_output --partial "astronvim_v6"
}

@test "config.nvim: without force skips existing directory config" {
    mkdir -p "$HOME/.config/nvim"

    run bash "$CONFIGURE"
    assert_success
    [[ -d "$HOME/.config/nvim" ]]
    [[ ! -L "$HOME/.config/nvim" ]]
}

@test "config.nvim: with force backs up existing directory config" {
    mkdir -p "$HOME/.config/nvim"
    echo "old config" > "$HOME/.config/nvim/init.lua"

    export PENNYKIT_FORCE="true"
    run bash "$CONFIGURE"
    assert_success
    [[ -L "$HOME/.config/nvim" ]]
    run find "$HOME/.config" -name "nvim.backup_*" -type d
    assert_success
    assert_output --partial "nvim.backup_"
}

@test "config.nvim: handles broken symlink" {
    ln -s "$BATS_TEST_TMPDIR/nonexistent" "$HOME/.config/nvim"

    run bash "$CONFIGURE"
    assert_success
    [[ -L "$HOME/.config/nvim" ]]
    run readlink -f "$HOME/.config/nvim"
    assert_output --partial "astronvim_v6"
}
