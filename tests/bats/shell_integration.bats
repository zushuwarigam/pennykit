load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    mkdir -p "$PENNYKIT_HOME" "$HOME"
}

# ── pennykit.bash ───────────────────────────────────────────────

@test "pennykit.bash sources shell.exports" {
    printf 'echo "sourced exports"\n' > "$PENNYKIT_HOME/pennykit_shell.exports"
    printf 'echo "sourced alias"\n' > "$PENNYKIT_HOME/pennykit_shell.alias"
    printf 'echo "sourced functions"\n' > "$PENNYKIT_HOME/pennykit_shell.functions"

    run bash -c "
    source '$PENNYKIT_HOME/pennykit_shell.exports'
    source '$PENNYKIT_HOME/pennykit_shell.alias'
    source '$PENNYKIT_HOME/pennykit_shell.functions'
    "
    assert_success
    assert_output --partial "sourced exports"
    assert_output --partial "sourced alias"
    assert_output --partial "sourced functions"
}

@test "pennykit.bash sets EDITOR and VISUAL" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.exports"
    [[ "$EDITOR" == "nvim" ]]
    [[ "$VISUAL" == "nvim" ]]
}

@test "pennykit_shell.exports sets HISTSIZE" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.exports"
    [[ "$HISTSIZE" == "10000" ]]
}

@test "pennykit_shell.exports extends PATH with expected directories" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.exports"
    [[ "$PATH" == *".local/bin"* ]]
    [[ "$PATH" == *".cargo/bin"* ]]
    [[ "$PATH" == *"go/bin"* ]]
}

@test "pennykit_shell.exports sets FZF_DEFAULT_COMMAND" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.exports"
    [[ "$FZF_DEFAULT_COMMAND" == *"rg --files"* ]]
}

@test "pennykit_shell.exports sets LANG" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.exports"
    [[ "$LANG" == "ru_RU.UTF-8" ]]
}

# ── pennykit_shell.alias ─────────────────────────────────────────

@test "pennykit_shell.alias defines vim aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.alias'
    alias v 2>/dev/null; alias vi 2>/dev/null; alias vim 2>/dev/null
    "
    assert_success
    assert_output --partial "nvim"
}

@test "pennykit_shell.alias defines git aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.alias'
    alias gs 2>/dev/null; alias ga 2>/dev/null; alias gc 2>/dev/null
    "
    assert_success
}

@test "pennykit_shell.alias defines docker aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.alias'
    alias dsp 2>/dev/null; alias di 2>/dev/null; alias dps 2>/dev/null
    "
    assert_success
}

# ── pennykit_shell.functions ────────────────────────────────────

@test "pennykit_shell.functions mkcd creates dir and enters it" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions"
    run mkcd "$BATS_TEST_TMPDIR/test_dir"
    assert_success
    [[ -d "$BATS_TEST_TMPDIR/test_dir" ]]
}

@test "pennykit_shell.functions bak creates .bak copy" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions"
    echo "content" > "$BATS_TEST_TMPDIR/testfile"
    run bak "$BATS_TEST_TMPDIR/testfile"
    assert_success
    [[ -f "$BATS_TEST_TMPDIR/testfile.bak" ]]
}

@test "pennykit_shell.functions orig creates .orig copy" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions"
    echo "content" > "$BATS_TEST_TMPDIR/testfile"
    run orig "$BATS_TEST_TMPDIR/testfile"
    assert_success
    [[ -f "$BATS_TEST_TMPDIR/testfile.orig" ]]
}

@test "pennykit_shell.functions define penny-update-extern" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions'
    declare -F penny-update-extern 2>/dev/null
    "
    assert_success
}

@test "pennykit_shell.functions define penny-theme" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions'
    declare -F penny-theme 2>/dev/null
    "
    assert_success
}

@test "pennykit_shell.functions define fzf_rg_nvim" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../pennykit_shell.functions'
    declare -F fzf_rg_nvim 2>/dev/null
    "
    assert_success
}
