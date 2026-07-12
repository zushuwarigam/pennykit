load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    mkdir -p "$PENNYKIT_HOME" "$HOME"
}

# ── pennykit.bash ───────────────────────────────────────────────

@test "pennykit.bash sources shell.exports" {
    mkdir -p "$PENNYKIT_HOME/shell"
    printf 'echo "sourced exports"\n' > "$PENNYKIT_HOME/shell/exports.sh"
    printf 'echo "sourced alias"\n' > "$PENNYKIT_HOME/shell/aliases.sh"
    printf 'echo "sourced functions"\n' > "$PENNYKIT_HOME/shell/functions.sh"

    run bash -c "
    source '$PENNYKIT_HOME/shell/exports.sh'
    source '$PENNYKIT_HOME/shell/aliases.sh'
    source '$PENNYKIT_HOME/shell/functions.sh'
    "
    assert_success
    assert_output --partial "sourced exports"
    assert_output --partial "sourced alias"
    assert_output --partial "sourced functions"
}

@test "pennykit.bash sets EDITOR and VISUAL" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/exports.sh"
    [[ "$EDITOR" == "nvim" ]]
    [[ "$VISUAL" == "nvim" ]]
}

@test "shell/exports.sh sets HISTSIZE" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/exports.sh"
    [[ "$HISTSIZE" == "10000" ]]
}

@test "shell/exports.sh extends PATH with expected directories" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/exports.sh"
    [[ "$PATH" == *".local/bin"* ]]
    [[ "$PATH" == *".cargo/bin"* ]]
    [[ "$PATH" == *"go/bin"* ]]
}

@test "shell/exports.sh sets FZF_DEFAULT_COMMAND" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/exports.sh"
    [[ "$FZF_DEFAULT_COMMAND" == *"rg --files"* ]]
}

@test "shell/exports.sh sets LANG" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/exports.sh"
    [[ "$LANG" == "ru_RU.UTF-8" ]]
}

# ── shell/aliases.sh ──────────────────────────────────────────

@test "shell/aliases.sh defines vim aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/aliases.sh'
    alias v 2>/dev/null; alias vi 2>/dev/null; alias vim 2>/dev/null
    "
    assert_success
    assert_output --partial "nvim"
}

@test "shell/aliases.sh defines git aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/aliases.sh'
    alias gs 2>/dev/null; alias ga 2>/dev/null; alias gc 2>/dev/null
    "
    assert_success
}

@test "shell/aliases.sh defines docker aliases" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/aliases.sh'
    alias dsp 2>/dev/null; alias di 2>/dev/null; alias dps 2>/dev/null
    "
    assert_success
}

# ── shell/functions.sh ────────────────────────────────────────

@test "shell/functions.sh mkcd creates dir and enters it" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh"
    run mkcd "$BATS_TEST_TMPDIR/test_dir"
    assert_success
    [[ -d "$BATS_TEST_TMPDIR/test_dir" ]]
}

@test "shell/functions.sh bak creates .bak copy" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh"
    echo "content" > "$BATS_TEST_TMPDIR/testfile"
    run bak "$BATS_TEST_TMPDIR/testfile"
    assert_success
    [[ -f "$BATS_TEST_TMPDIR/testfile.bak" ]]
}

@test "shell/functions.sh orig creates .orig copy" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh"
    echo "content" > "$BATS_TEST_TMPDIR/testfile"
    run orig "$BATS_TEST_TMPDIR/testfile"
    assert_success
    [[ -f "$BATS_TEST_TMPDIR/testfile.orig" ]]
}

@test "shell/functions.sh define penny-update-extern" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh'
    declare -F penny-update-extern 2>/dev/null
    "
    assert_success
}

@test "shell/functions.sh define penny-theme" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh'
    declare -F penny-theme 2>/dev/null
    "
    assert_success
}

@test "shell/functions.sh define fzf_rg_nvim" {
    run bash -c "
    source '$(dirname "$BATS_TEST_FILENAME")/../../shell/functions.sh'
    declare -F fzf_rg_nvim 2>/dev/null
    "
    assert_success
}
