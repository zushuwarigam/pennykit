load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/configs
    mkdir -p "$HOME"
    source "$PENNYKIT_HOME/../lib/helpers.sh" 2>/dev/null || \
        source "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh"
}

@test "_verify_sha256: matches passes" {
    echo "hello" > "$BATS_TEST_TMPDIR/testfile"
    local expected
    expected=$(sha256sum "$BATS_TEST_TMPDIR/testfile" | awk '{print $1}')
    run _verify_sha256 "$BATS_TEST_TMPDIR/testfile" "$expected"
    assert_success
    assert_output --partial "SHA256 verified"
}

@test "_verify_sha256: mismatch fails" {
    echo "hello" > "$BATS_TEST_TMPDIR/testfile"
    run _verify_sha256 "$BATS_TEST_TMPDIR/testfile" "0000000000000000000000000000000000000000000000000000000000000000"
    assert_failure
    assert_output --partial "SHA256 mismatch"
}

@test "_is_deactivated: active package returns false" {
    echo "# comment" > "$PENNYKIT_HOME/configs/extern.skip"
    echo "yazi" >> "$PENNYKIT_HOME/configs/extern.skip"
    run _is_deactivated "yazi"
    assert_success
    run _is_deactivated "nvim"
    assert_failure
}

@test "_is_deactivated: missing skip file returns false" {
    run _is_deactivated "dive"
    assert_failure
}

@test "_readlinkf: resolves symlinks" {
    echo "target" > "$BATS_TEST_TMPDIR/target"
    ln -s "$BATS_TEST_TMPDIR/target" "$BATS_TEST_TMPDIR/link"
    run _readlinkf "$BATS_TEST_TMPDIR/link"
    assert_output "$BATS_TEST_TMPDIR/target"
}

@test "_readlinkf: returns same path for regular file" {
    echo "data" > "$BATS_TEST_TMPDIR/regular"
    run _readlinkf "$BATS_TEST_TMPDIR/regular"
    assert_output "$BATS_TEST_TMPDIR/regular"
}

@test "_cleanup_on_exit: removes temp files" {
    touch "$BATS_TEST_TMPDIR/temp1" "$BATS_TEST_TMPDIR/temp2"
    _cleanup_on_exit "$BATS_TEST_TMPDIR/temp1" "$BATS_TEST_TMPDIR/temp2"
    assert [ ! -f "$BATS_TEST_TMPDIR/temp1" ]
    assert [ ! -f "$BATS_TEST_TMPDIR/temp2" ]
}

@test "_cleanup_on_exit: does not fail on missing files" {
    touch "$BATS_TEST_TMPDIR/existing"
    _cleanup_on_exit "$BATS_TEST_TMPDIR/nonexistent"
    _cleanup_on_exit "$BATS_TEST_TMPDIR/existing"
    assert [ ! -f "$BATS_TEST_TMPDIR/existing" ]
}

@test "_curl: includes -fL flags" {
    run _curl --version
    assert_success
    assert_output --partial "curl"
}

# ── _mark_problematic / _clear_problematic ───────────────────────

@test "_mark_problematic: creates file and adds package" {
    run _mark_problematic "fzf"
    assert_success
    assert [ -f "$PENNYKIT_HOME/configs/extern.problematic" ]
    run cat "$PENNYKIT_HOME/configs/extern.problematic"
    assert_output "fzf"
}

@test "_mark_problematic: does not duplicate entries" {
    _mark_problematic "fzf"
    _mark_problematic "fzf"
    run cat "$PENNYKIT_HOME/configs/extern.problematic"
    assert_output "fzf"
}

@test "_clear_problematic: removes package from file" {
    _mark_problematic "fzf"
    _mark_problematic "dive"
    _clear_problematic "fzf"
    run cat "$PENNYKIT_HOME/configs/extern.problematic"
    assert_output "dive"
}

@test "_clear_problematic: removes file when empty" {
    _mark_problematic "fzf"
    _clear_problematic "fzf"
    assert [ ! -f "$PENNYKIT_HOME/configs/extern.problematic" ]
}

@test "_clear_problematic: does nothing for missing file" {
    run _clear_problematic "nonexistent"
    assert_success
}

@test "_clear_problematic: does nothing for non-listed package" {
    _mark_problematic "fzf"
    _clear_problematic "dive"
    run cat "$PENNYKIT_HOME/configs/extern.problematic"
    assert_output "fzf"
}
