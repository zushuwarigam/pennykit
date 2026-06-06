load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/{bin,configs/themes,lib,packages,scripts,nvim-starter}
    mkdir -p "$HOME"/.config
    ln -s "$BATS_TEST_TMPDIR" "$PENNYKIT_HOME/.." 2>/dev/null || true

    PENNYKIT_BIN="$PENNYKIT_HOME/../bin/pennykit"
    if [[ ! -f "$PENNYKIT_BIN" ]]; then
        PENNYKIT_BIN="$(dirname "$BATS_TEST_FILENAME")/../../bin/pennykit"
    fi

    cp "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh" "$PENNYKIT_HOME/lib/helpers.sh"
    echo "PENNYKIT_THEME_NAME=test" > "$PENNYKIT_HOME/configs/themes/test.conf"
    echo "PENNYKIT_THEME_NAME=luna" > "$PENNYKIT_HOME/configs/themes/luna.conf"
}

@test "pennykit help shows usage" {
    run bash "$PENNYKIT_BIN" help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "doctor"
    assert_output --partial "clean"
}

@test "pennykit doctor: all checks on fresh install" {
    git init "$PENNYKIT_HOME"
    run bash "$PENNYKIT_BIN" doctor
    assert_success
    assert_output --partial "PennyKit doctor"
}

@test "pennykit status: shows dashboard" {
    git init "$PENNYKIT_HOME"
    git -C "$PENNYKIT_HOME" config user.email "test@test.com"
    git -C "$PENNYKIT_HOME" config user.name "Test"
    touch "$PENNYKIT_HOME/packages/extern.packages"
    run bash "$PENNYKIT_BIN" status
    assert_success
    assert_output --partial "PennyKit status"
}

@test "pennykit theme list: shows available themes" {
    run bash "$PENNYKIT_BIN" theme list
    assert_success
    assert_output --partial "test"
    assert_output --partial "luna"
}

@test "pennykit extern deactivate: creates skip file" {
    git init "$PENNYKIT_HOME"
    mkdir -p "$PENNYKIT_HOME/packages"
    touch "$PENNYKIT_HOME/packages/extern.packages"
    run bash "$PENNYKIT_BIN" extern deactivate "dive"
    assert_success
    assert_output --partial "Deactivated: dive"
    assert [ -f "$PENNYKIT_HOME/configs/extern.skip" ]
}

@test "pennykit extern list-deactivated: shows deactivated" {
    echo "dive" > "$PENNYKIT_HOME/configs/extern.skip"
    run bash "$PENNYKIT_BIN" extern list-deactivated
    assert_success
    assert_output --partial "dive"
}

@test "pennykit extern activate: removes from skip file" {
    echo "dive" > "$PENNYKIT_HOME/configs/extern.skip"
    run bash "$PENNYKIT_BIN" extern activate "dive"
    assert_success
    assert_output --partial "Activated: dive"
    assert [ ! -f "$PENNYKIT_HOME/configs/extern.skip" ]
}

@test "pennykit clean: handles missing symlinks gracefully" {
    run bash "$PENNYKIT_BIN" clean
    assert_success
    assert_output --partial "PennyKit clean"
}

@test "pennykit branch: shows current branch" {
    git init "$PENNYKIT_HOME"
    run bash "$PENNYKIT_BIN" branch
    assert_success
}
