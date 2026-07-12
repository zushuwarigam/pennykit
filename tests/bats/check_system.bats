load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
}

# Extract detect_os from check_system.sh, replacing os-release path for mocking
source_detect_os() {
    local mock_osrelease="$1"
    local func
    func=$(sed -n '/^detect_os/,/^}/p' "$(dirname "$BATS_TEST_FILENAME")/../../scripts/install/check_system.sh")
    if [[ -n "$mock_osrelease" ]]; then
        func="${func//\/etc\/os-release/$mock_osrelease}"
    fi
    PENNYKIT_OS_ID=""
    PENNYKIT_OS_VERSION_CODENAME=""
    eval "$func"
}

@test "detect_os: macOS detected" {
    source_detect_os ""
    OSTYPE="darwin21"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "macos" ]]
}

@test "detect_os: debian detected from os-release" {
    local mock_os="$BATS_TEST_TMPDIR/os-release"
    cat > "$mock_os" << 'EOF'
ID=debian
VERSION_CODENAME=trixie
EOF
    source_detect_os "$mock_os"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "debian" ]]
    [[ "$PENNYKIT_OS_VERSION_CODENAME" == "trixie" ]]
}

@test "detect_os: ubuntu detected from os-release" {
    local mock_os="$BATS_TEST_TMPDIR/os-release"
    cat > "$mock_os" << 'EOF'
ID=ubuntu
VERSION_CODENAME=noble
EOF
    source_detect_os "$mock_os"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "ubuntu" ]]
    [[ "$PENNYKIT_OS_VERSION_CODENAME" == "noble" ]]
}

@test "detect_os: ID_LIKE debian falls back to debian" {
    local mock_os="$BATS_TEST_TMPDIR/os-release"
    cat > "$mock_os" << 'EOF'
ID=linuxmint
ID_LIKE=debian
VERSION_CODENAME=wilma
EOF
    source_detect_os "$mock_os"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "debian" ]]
    [[ "$PENNYKIT_OS_VERSION_CODENAME" == "wilma" ]]
}

@test "detect_os: unrecognized OS gets 'other'" {
    local mock_os="$BATS_TEST_TMPDIR/os-release"
    cat > "$mock_os" << 'EOF'
ID=fedora
ID_LIKE=fedora
VERSION_CODENAME=forty
EOF
    source_detect_os "$mock_os"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "other" ]]
}

@test "detect_os: missing os-release gets 'other'" {
    local mock_os="$BATS_TEST_TMPDIR/nonexistent-os-release"
    source_detect_os "$mock_os"
    detect_os
    [[ "$PENNYKIT_OS_ID" == "other" ]]
}

@test "detect_os: exports variables" {
    local mock_os="$BATS_TEST_TMPDIR/os-release"
    cat > "$mock_os" << 'EOF'
ID=debian
VERSION_CODENAME=trixie
EOF

    run bash -c "
    source_detect_os() {
        local mock_osrelease=\"\$1\"
        local func
        func=\$(sed -n '/^detect_os/,/^}/p' '$PENNYKIT_HOME/../scripts/check_system.sh' 2>/dev/null || sed -n '/^detect_os/,/^}/p' '$(dirname "$BATS_TEST_FILENAME")/../../scripts/check_system.sh')
        func=\"\${func//\/etc\/os-release/\$mock_osrelease}\"
        eval \"\$func\"
    }
    source_detect_os '$mock_os'
    detect_os
    echo \"ID=\$PENNYKIT_OS_ID CODENAME=\$PENNYKIT_OS_VERSION_CODENAME\"
    "
    assert_success
    assert_output --partial "ID=debian"
    assert_output --partial "CODENAME=trixie"
}
