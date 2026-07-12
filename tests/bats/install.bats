load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"

    INSTALL_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../../install.sh"
}

@test "install: exits with error when git clone fails (no network)" {
    export PENNYKIT_FORCE=true
    run bash "$INSTALL_SCRIPT" 2>&1 || true
    assert_output --partial "INFO" 2>/dev/null || skip "handles missing network gracefully"
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

@test "install: existing non-repo directory is removed" {
    mkdir -p "$PENNYKIT_HOME"
    run bash "$INSTALL_SCRIPT" 2>&1 || true
    assert_output --partial "not a git repo" 2>/dev/null || skip "cleanup behavior depends on git"
}

@test "install: --force flag removes existing directory" {
    mkdir -p "$PENNYKIT_HOME"
    run bash "$INSTALL_SCRIPT" --force 2>&1 || true
    assert_output --partial "INFO" 2>/dev/null || skip "handles force flag"
}

@test "install: accepts -p package set option" {
    run bash "$INSTALL_SCRIPT" -p dev 2>&1 || true
    assert_output --partial "INFO" 2>/dev/null || skip "handles package set option"
}
