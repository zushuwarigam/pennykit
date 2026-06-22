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

@test "pennykit extern list-problematic: shows problematic packages" {
    mkdir -p "$PENNYKIT_HOME/configs"
    echo "badpkg" > "$PENNYKIT_HOME/configs/extern.problematic"
    echo "anotherpkg" >> "$PENNYKIT_HOME/configs/extern.problematic"
    git init "$PENNYKIT_HOME"
    mkdir -p "$PENNYKIT_HOME/packages"
    touch "$PENNYKIT_HOME/packages/extern.packages"
    run bash "$PENNYKIT_BIN" extern list-problematic
    assert_success
    assert_output --partial "badpkg"
    assert_output --partial "anotherpkg"
}

@test "pennykit extern list-problematic: shows message when no file" {
    git init "$PENNYKIT_HOME"
    mkdir -p "$PENNYKIT_HOME/packages"
    touch "$PENNYKIT_HOME/packages/extern.packages"
    run bash "$PENNYKIT_BIN" extern list-problematic
    assert_success
    assert_output --partial "No problematic"
}

@test "pennykit extern reset-problematic: clears file" {
    mkdir -p "$PENNYKIT_HOME/configs"
    echo "badpkg" > "$PENNYKIT_HOME/configs/extern.problematic"
    git init "$PENNYKIT_HOME"
    mkdir -p "$PENNYKIT_HOME/packages"
    touch "$PENNYKIT_HOME/packages/extern.packages"
    run bash "$PENNYKIT_BIN" extern reset-problematic
    assert_success
    assert [ ! -f "$PENNYKIT_HOME/configs/extern.problematic" ]
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

# ── _nvim_config_type ───────────────────────────────────────────

@test "_nvim_config_type: returns 'none' when no config directory" {
    source "$PENNYKIT_HOME/lib/helpers.sh"
    eval "$(sed -n '/^_nvim_config_type/,/^}/p' "$PENNYKIT_BIN")"
    run _nvim_config_type
    assert_success
    assert_output "none"
}

@test "_nvim_config_type: returns 'directory' when regular directory exists" {
    mkdir -p "$HOME/.config/nvim"
    source "$PENNYKIT_HOME/lib/helpers.sh"
    eval "$(sed -n '/^_nvim_config_type/,/^}/p' "$PENNYKIT_BIN")"
    run _nvim_config_type
    assert_success
    assert_output "directory"
}

@test "_nvim_config_type: returns 'symlink' when linked to nvim-starter" {
    mkdir -p "$HOME/.config"
    mkdir -p "$PENNYKIT_HOME/nvim-starter/astronvim_v6"
    ln -s "$PENNYKIT_HOME/nvim-starter/astronvim_v6" "$HOME/.config/nvim"
    source "$PENNYKIT_HOME/lib/helpers.sh"
    eval "$(sed -n '/^_nvim_config_type/,/^}/p' "$PENNYKIT_BIN")"
    run _nvim_config_type
    assert_success
    assert_output "symlink"
}

@test "_nvim_config_type: returns 'external_symlink' when linked elsewhere" {
    mkdir -p "$HOME/.config"
    mkdir -p "$BATS_TEST_TMPDIR/external"
    ln -s "$BATS_TEST_TMPDIR/external" "$HOME/.config/nvim"
    source "$PENNYKIT_HOME/lib/helpers.sh"
    eval "$(sed -n '/^_nvim_config_type/,/^}/p' "$PENNYKIT_BIN")"
    run _nvim_config_type
    assert_success
    assert_output "external_symlink"
}

@test "cmd_nvim: select creates symlink when type is 'none'" {
    mkdir -p "$PENNYKIT_HOME/nvim-starter/astronvim_v6"
    run bash "$PENNYKIT_BIN" nvim <<< "1"
    assert_success
    [[ -L "$HOME/.config/nvim" ]]
}

@test "cmd_nvim: switching configs removes nvim data dirs" {
    mkdir -p "$PENNYKIT_HOME/nvim-starter/astronvim_v6"
    mkdir -p "$PENNYKIT_HOME/nvim-starter/lazyvim"
    ln -s "$PENNYKIT_HOME/nvim-starter/astronvim_v6" "$HOME/.config/nvim"
    mkdir -p "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
    run bash "$PENNYKIT_BIN" nvim <<< "2"
    assert_success
    [[ ! -d "$HOME/.local/share/nvim" ]]
    [[ ! -d "$HOME/.local/state/nvim" ]]
    [[ ! -d "$HOME/.cache/nvim" ]]
}

@test "cmd_nvim: disable removes symlink" {
    mkdir -p "$PENNYKIT_HOME/nvim-starter/astronvim_v6"
    mkdir -p "$PENNYKIT_HOME/nvim-starter/lazyvim"
    mkdir -p "$PENNYKIT_HOME/nvim-starter/kickstart"
    ln -s "$PENNYKIT_HOME/nvim-starter/astronvim_v6" "$HOME/.config/nvim"
    # Option 3 is the find order: astronvim_v6 -> lazyvim -> kickstart -> "Disable nvim config" (index 4? let's verify)
    # Actually with 3 dirs + "Disable" = 4 options, "Disable" is option 4
    run bash "$PENNYKIT_BIN" nvim <<< "4"
    assert_success
    [[ ! -e "$HOME/.config/nvim" ]]
}

@test "cmd_nvim: shows available configs" {
    mkdir -p "$PENNYKIT_HOME/nvim-starter/astronvim_v6"
    mkdir -p "$PENNYKIT_HOME/nvim-starter/lazyvim"
    run bash "$PENNYKIT_BIN" nvim <<< "1"
    assert_success
    assert_output --partial "astronvim_v6"
    assert_output --partial "lazyvim"
}

# ── cmd_extern with package sets ────────────────────────────────

setup_extern_set() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/{packages,scripts,configs}

    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EXTERNEOF'
PENNYKIT_EXTERN_DEFAULT=(alpha)
PENNYKIT_EXTERN_ADMIN=(beta)
PENNYKIT_EXTERN_DEV=(gamma)
PENNYKIT_EXTERN_PENTEST=(delta)

add_alpha() { echo "Adding alpha"; }
add_beta()  { echo "Adding beta"; }
add_gamma() { echo "Adding gamma"; }
add_delta() { echo "Adding delta"; }
EXTERNEOF

    cp "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh" "$PENNYKIT_HOME/lib/helpers.sh"
    touch "$PENNYKIT_HOME/scripts/check_system.sh"

    PENNYKIT_BIN="$PENNYKIT_HOME/../bin/pennykit"
    if [[ ! -f "$PENNYKIT_BIN" ]]; then
        PENNYKIT_BIN="$(dirname "$BATS_TEST_FILENAME")/../../bin/pennykit"
    fi
}

@test "cmd_extern: default set processes DEFAULT packages" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern default
    assert_success
    assert_output --partial "Adding alpha"
    refute_output --partial "Adding beta"
    refute_output --partial "Adding gamma"
    refute_output --partial "Adding delta"
}

@test "cmd_extern: admin set processes ADMIN packages" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern admin
    assert_success
    assert_output --partial "Adding beta"
}

@test "cmd_extern: dev set processes DEV packages" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern dev
    assert_success
    assert_output --partial "Adding gamma"
}

@test "cmd_extern: pentest set processes PENTEST packages" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern pentest
    assert_success
    assert_output --partial "Adding delta"
}

@test "cmd_extern: all set processes all tiers" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern all
    assert_success
    assert_output --partial "Adding alpha"
    assert_output --partial "Adding beta"
    assert_output --partial "Adding gamma"
    assert_output --partial "Adding delta"
}

@test "cmd_extern: no args defaults to default set" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern
    assert_success
    assert_output --partial "Adding alpha"
}

@test "cmd_extern: unknown set shows usage error" {
    setup_extern_set
    run bash "$PENNYKIT_BIN" extern unknownset
    assert_failure
    assert_output --partial "Usage"
}

@test "cmd_extern: retry-problematic re-attempts failed packages" {
    setup_extern_set
    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EXTERNEOF'
PENNYKIT_EXTERN_DEFAULT=(alpha)
add_alpha() { echo "Adding alpha"; }
EXTERNEOF
    echo "alpha" > "$PENNYKIT_HOME/configs/extern.problematic"
    run bash "$PENNYKIT_BIN" extern default
    assert_success
    assert_output --partial "Retrying problematic"
    assert_output --partial "alpha: retrying add_alpha"
}

@test "cmd_extern: retry-problematic skips already-installed packages" {
    setup_extern_set
    echo "true" > "$PENNYKIT_HOME/configs/extern.problematic"
    run bash "$PENNYKIT_BIN" extern default
    assert_success
    assert_output --partial "already installed, removing from problematic list"
}
