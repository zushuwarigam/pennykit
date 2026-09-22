load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # install.sh derives its own PENNYKIT_HOME from $HOME — keep the two in sync
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_HOME="$HOME/.pennykit"
    mkdir -p "$HOME"

    INSTALL_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../../install.sh"

    # Hermetic network: a git shim on PATH that fails clone/rev-parse deterministically
    # so no test ever touches the real remote. The shim forwards nothing to real git.
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<'SHIM'
#!/usr/bin/env bash
case "$*" in
    *clone*)
        echo "fatal: could not read from remote repository." >&2
        exit 128 ;;
    *rev-parse*)
        echo "fatal: not a git repository (or any of the parent directories): .git" >&2
        exit 128 ;;
    *)
        exit 0 ;;
esac
SHIM
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "install: --help shows usage" {
    run bash "$INSTALL_SCRIPT" --help
    assert_success
    assert_output --partial "Usage:"
}

@test "install: -h shows usage" {
    run bash "$INSTALL_SCRIPT" -h
    assert_success
    assert_output --partial "Usage:"
}

@test "install: clone failure surfaces ERROR and nonzero exit" {
    run bash "$INSTALL_SCRIPT"
    assert_failure
    assert_output --partial "Failed to clone repository"
}

@test "install: existing non-repo directory is removed before re-clone" {
    mkdir -p "$PENNYKIT_HOME"
    echo "stale" > "$PENNYKIT_HOME/stale-file"
    run bash "$INSTALL_SCRIPT"
    assert_failure
    assert_output --partial "not a git repo"
    assert_output --partial "Failed to clone repository"
}

@test "install: --force removes existing directory" {
    mkdir -p "$PENNYKIT_HOME"
    echo "stale" > "$PENNYKIT_HOME/stale-file"
    run bash "$INSTALL_SCRIPT" --force
    assert_failure
    assert_output --partial "INFO: --force supplied"
    assert_output --partial "Failed to clone repository"
}

@test "install: accepts -p package set option" {
    run bash "$INSTALL_SCRIPT" -p dev
    # A valid set must proceed past usage parsing (failing later only at the mocked clone)
    assert_output --partial "Cloning PennyKit"
    refute_output --partial "Usage:"
}

@test "install: invalid package set prints usage" {
    run bash "$INSTALL_SCRIPT" -p bogus
    assert_output --partial "Usage:"
}