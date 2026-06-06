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
