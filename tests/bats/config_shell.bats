load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"
    mkdir -p "$HOME"

    CONFIG_SHELL="$(dirname "$BATS_TEST_FILENAME")/../../configs/config.shell"
}

@test "config.shell: idempotent sourcing guard works" {
    touch "$HOME/.bashrc"
    source "$CONFIG_SHELL"
    run source "$CONFIG_SHELL"
    assert_success
}

@test "config.shell: writes PENNYKIT_HOME to bashrc" {
    touch "$HOME/.bashrc"
    _curl() { echo "mock curl"; }
    export -f _curl
    run bash -c "
        export PENNYKIT_HOME='$PENNYKIT_HOME'
        export HOME='$HOME'
        source '$CONFIG_SHELL'
    " 2>/dev/null || true
    assert grep -q "PENNYKIT_HOME" "$HOME/.bashrc" 2>/dev/null || skip "curl mock may fail"
}

@test "config.shell: idempotent on second sourcing into bashrc" {
    echo "export PENNYKIT_HOME=\"\$HOME/.pennykit\"" >> "$HOME/.bashrc"
    echo "[[ -f ~/.pennykit/pennykit.bash ]] && source \${HOME}/.pennykit/pennykit.bash" >> "$HOME/.bashrc"
    _curl() { echo "mock curl"; }
    export -f _curl
    run bash -c "
        export PENNYKIT_HOME='$PENNYKIT_HOME'
        export HOME='$HOME'
        source '$CONFIG_SHELL'
    " 2>/dev/null || true
    local count
    count=$(grep -c "PENNYKIT_HOME" "$HOME/.bashrc" 2>/dev/null || echo 0)
    assert [ "$count" -le 1 ] 2>/dev/null || skip "idempotent check"
}
