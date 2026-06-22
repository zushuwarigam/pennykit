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

# ── pipx layer processing ───────────────────────────────────────

@test "package_installer: processes pipx dev packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    cat > "$PENNYKIT_HOME/packages/pipx.dev" << 'EOF'
PENNYKIT_PIPX_DEV=(poetry black)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] pipx install poetry black"
}

@test "package_installer: processes pipx admin packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=ADMIN
    cat > "$PENNYKIT_HOME/packages/pipx.admin" << 'EOF'
PENNYKIT_PIPX_ADMIN=(httpie)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] pipx install httpie"
}

@test "package_installer: processes pipx pentest packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=PENTEST
    cat > "$PENNYKIT_HOME/packages/pipx.pentest" << 'EOF'
PENNYKIT_PIPX_PENTEST=(sqlmap)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] pipx install sqlmap"
}

@test "package_installer: deduplicates pipx packages across layers" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=ALL
    cat > "$PENNYKIT_HOME/packages/pipx.admin" << 'EOF'
PENNYKIT_PIPX_ADMIN=(common)
EOF
    cat > "$PENNYKIT_HOME/packages/pipx.dev" << 'EOF'
PENNYKIT_PIPX_DEV=(common tool)
EOF
    cat > "$PENNYKIT_HOME/packages/pipx.pentest" << 'EOF'
PENNYKIT_PIPX_PENTEST=(common)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    # "common" should appear only once
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    # Count occurrences of "common" in pipx install calls
    local count
    count=$(grep -c "pipx install common" <<< "$output" || true)
    [[ "$count" -eq 1 ]]
}

# ── npm layer processing ────────────────────────────────────────

@test "package_installer: processes npm default packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/npm.default" << 'EOF'
PENNYKIT_NPM_DEFAULT=(tree-sitter-cli)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] npm install -g tree-sitter-cli"
}

@test "package_installer: processes npm dev packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    mkdir -p "$PENNYKIT_HOME/packages"
    cat > "$PENNYKIT_HOME/packages/npm.dev" << 'EOF'
PENNYKIT_NPM_DEV=(typescript)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] npm install typescript"
}

@test "package_installer: deduplicates npm packages across layers" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=ALL
    cat > "$PENNYKIT_HOME/packages/npm.admin" << 'EOF'
PENNYKIT_NPM_ADMIN=(shared)
EOF
    cat > "$PENNYKIT_HOME/packages/npm.dev" << 'EOF'
PENNYKIT_NPM_DEV=(shared tool)
EOF
    cat > "$PENNYKIT_HOME/packages/npm.pentest" << 'EOF'
PENNYKIT_NPM_PENTEST=(shared)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    local count
    count=$(grep -c "npm install shared" <<< "$output" || true)
    [[ "$count" -eq 1 ]]
}

@test "package_installer: processes both pipx and npm in same run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    cat > "$PENNYKIT_HOME/packages/pipx.dev" << 'EOF'
PENNYKIT_PIPX_DEV=(poetry)
EOF
    cat > "$PENNYKIT_HOME/packages/npm.dev" << 'EOF'
PENNYKIT_NPM_DEV=(typescript)
EOF
    run bash "$PENNYKIT_HOME/scripts/package_installer.sh" apt
    assert_success
    assert_output --partial "pipx install poetry"
    assert_output --partial "npm install typescript"
}
