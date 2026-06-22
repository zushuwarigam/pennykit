load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_OS_ID=1
    mkdir -p "$PENNYKIT_HOME"/{packages,scripts,lib}

    cp "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh" "$PENNYKIT_HOME/lib/helpers.sh"

    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(curl git)
EOF

    cat > "$PENNYKIT_HOME/packages/apt.default.postinst" << 'EOF'
echo "postinst executed"
EOF

    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EOF'
PENNYKIT_EXTERN_DEFAULT=(dive)
add_dive() { echo "Installing dive"; }
EOF

    INSTALLER="$PENNYKIT_HOME/../scripts/package_installer.sh"
    if [[ ! -f "$INSTALLER" ]]; then
        INSTALLER="$(dirname "$BATS_TEST_FILENAME")/../../scripts/package_installer.sh"
    fi

    cp "$(dirname "$BATS_TEST_FILENAME")/../../scripts/package_installer.sh" "$PENNYKIT_HOME/scripts/package_installer.sh"
    cp "$(dirname "$BATS_TEST_FILENAME")/../../scripts/check_system.sh" "$PENNYKIT_HOME/scripts/check_system.sh" 2>/dev/null || true
}

@test "package_installer: dry-run prints commands without executing" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "DRY-RUN"
}

@test "package_installer: sources apt.default and processes layers" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "DRY-RUN"
}

@test "package_installer: skips deactivated packages" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    mkdir -p "$PENNYKIT_HOME/configs"
    echo "dive" > "$PENNYKIT_HOME/configs/extern.skip"
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
}

@test "package_installer: rootless creates local directories" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    local rootless_dir="$BATS_TEST_TMPDIR/rootless-local"
    export PENNYKIT_LOCAL_DIR="$rootless_dir"
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert [ -d "$rootless_dir/bin" ]
    assert [ -d "$rootless_dir/opt" ]
    assert [ -d "$rootless_dir/go" ]
}

@test "package_installer: rootless skips apt commands" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "ROOTLESS"
    assert_output --partial "Skipping apt install"
}

@test "package_installer: rootless overrides dry-run for apt" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    # Rootless header is printed
    assert_output --partial "Rootless mode"
    # apt operations show ROOTLESS, not DRY-RUN
    assert_output --partial "[ROOTLESS]"
    refute_output --partial "[DRY-RUN] Skipping apt"
}

@test "package_installer: rootless installs registered apt packages via alternative" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    mkdir -p "$PENNYKIT_HOME/packages"
    # Mock apt.rootless with a registered package
    cat > "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
declare -A _ROOTLESS_APT
_ROOTLESS_APT[bat]=_apt_rootless_bat
_apt_rootless_bat() { echo "  Installing bat via rootless alternative"; }
EOF
    # Override apt.default to include bat
    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT+=(bat)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "bat via rootless alternative"
}

@test "package_installer: rootless skips unregistered apt packages" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    mkdir -p "$PENNYKIT_HOME/packages"
    # Mock apt.rootless with no overlap to apt.default
    cat > "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
declare -A _ROOTLESS_APT
_ROOTLESS_APT[bat]=_apt_rootless_bat
_apt_rootless_bat() { echo "  Installing bat"; }
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    # curl and git are in apt.default but not in _ROOTLESS_APT
    assert_output --partial "no rootless alternative"
    refute_output --partial "Installing bat"
}
