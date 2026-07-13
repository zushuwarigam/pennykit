load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$PENNYKIT_HOME"/{configs,lib}
    mkdir -p "$HOME/.local/bin"

    SANE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    source "$PENNYKIT_HOME/../lib/helpers.sh" 2>/dev/null || \
        source "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh"
}

# ── _verify_or_warn_sha256 ──────────────────────────────────────

@test "_verify_or_warn_sha256: missing checksum file aborts and returns 1" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _verify_or_warn_sha256 "/tmp/nonexistent.bin" "/tmp/nonexistent.sum"
    assert_failure
    assert_output --partial "ERROR"
    assert_output --partial "checksum file missing"
}

@test "_verify_or_warn_sha256: invalid checksum format aborts and returns 1" {
    printf '<!DOCTYPE html>\n<html>\n<head>\n</head>\n</html>\n' > "$BATS_TEST_TMPDIR/invalid.sum"
    echo "hello" > "$BATS_TEST_TMPDIR/dummy.bin"
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _verify_or_warn_sha256 "$BATS_TEST_TMPDIR/dummy.bin" "$BATS_TEST_TMPDIR/invalid.sum"
    assert_failure
    assert_output --partial "ERROR"
    assert_output --partial "invalid checksum format"
}

@test "_verify_or_warn_sha256: valid checksum calls _verify_sha256" {
    echo "hello" > "$BATS_TEST_TMPDIR/dummy.bin"
    local hash
    hash=$(sha256sum "$BATS_TEST_TMPDIR/dummy.bin" | awk '{print $1}')
    echo "$hash" > "$BATS_TEST_TMPDIR/dummy.sum"
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _verify_or_warn_sha256 "$BATS_TEST_TMPDIR/dummy.bin" "$BATS_TEST_TMPDIR/dummy.sum"
    assert_success
    assert_output --partial "SHA256 verified"
}

@test "_verify_or_warn_sha256: sha256 mismatch returns 1" {
    echo "content a" > "$BATS_TEST_TMPDIR/dummy.bin"
    local hash
    hash=$(sha256sum "$BATS_TEST_TMPDIR/dummy.bin" | awk '{print $1}')
    echo "$hash" > "$BATS_TEST_TMPDIR/dummy.sum"
    echo "content b" > "$BATS_TEST_TMPDIR/dummy.bin"
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _verify_or_warn_sha256 "$BATS_TEST_TMPDIR/dummy.bin" "$BATS_TEST_TMPDIR/dummy.sum"
    assert_failure
    assert_output --partial "SHA256 mismatch"
}

# ── add_hadolint ────────────────────────────────────────────────

hadolint_mock_curl() {
    case "$*" in
        *releases/latest*)
            echo '{"tag_name":"v2.12.0"}'
            ;;
        *hadolint-linux-x86_64.sha256*)
            local f=/tmp/hadolint-linux-x86_64
            if [[ -f "$f" ]]; then
                local hash
                hash=$(sha256sum "$f" | awk '{print $1}')
                printf '%s  %s\n' "$hash" "hadolint-linux-x86_64" > /tmp/hadolint-linux-x86_64.sha256
            fi
            ;;
        *hadolint-linux-x86_64)
            printf 'fake binary content\n' > /tmp/hadolint-linux-x86_64
            ;;
    esac
    return 0
}

@test "add_hadolint: installs binary when not present" {
    _curl() { hadolint_mock_curl "$@"; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    PATH="$SANE_PATH:$HOME/.local/bin" run add_hadolint
    assert_success
    assert_output --partial "Add external package: hadolint"
    assert [ -x "$HOME/.local/bin/hadolint" ]
    assert [ ! -f /tmp/hadolint-linux-x86_64 ]
    assert [ ! -f /tmp/hadolint-linux-x86_64.sha256 ]
}

@test "add_hadolint: skips if already installed" {
    touch "$HOME/.local/bin/hadolint"
    chmod +x "$HOME/.local/bin/hadolint"
    _curl() { echo "should not be called"; return 1; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    PATH="$SANE_PATH:$HOME/.local/bin" run add_hadolint
    assert_success
    assert_output --partial "Add external package: hadolint"
}

@test "update_hadolint: updates when installed" {
    touch "$HOME/.local/bin/hadolint"
    chmod +x "$HOME/.local/bin/hadolint"
    _curl() { hadolint_mock_curl "$@"; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    PATH="$SANE_PATH:$HOME/.local/bin" run update_hadolint
    assert_success
    assert_output --partial "Update external package: hadolint"
    assert [ -x "$HOME/.local/bin/hadolint" ]
}

@test "update_hadolint: skips if not installed" {
    _curl() { echo "should not be called"; return 1; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    PATH="$SANE_PATH" run update_hadolint
    assert_success
    assert_output --partial "Update external package: hadolint"
}

# ── _install_yazi_prebuilt ──────────────────────────────────────

yazi_mock_curl() {
    case "$*" in
        *releases/latest*)
            echo '{"tag_name":"v0.4.0"}'
            ;;
        *yazi-x86_64-unknown-linux-gnu.zip.sha256*)
            local f=/tmp/yazi-x86_64-unknown-linux-gnu.zip
            if [[ -f "$f" ]]; then
                local hash
                hash=$(sha256sum "$f" | awk '{print $1}')
                printf '%s  %s\n' "$hash" "yazi-x86_64-unknown-linux-gnu.zip" > /tmp/yazi-x86_64-unknown-linux-gnu.zip.sha256
            fi
            ;;
        *yazi-x86_64-unknown-linux-gnu.zip)
            mkdir -p /tmp/yz/yazi-x86_64-unknown-linux-gnu
            printf 'yazi-binary\n' > /tmp/yz/yazi-x86_64-unknown-linux-gnu/yazi
            printf 'ya-binary\n' > /tmp/yz/yazi-x86_64-unknown-linux-gnu/ya
            (cd /tmp/yz && zip -q -r /tmp/yazi-x86_64-unknown-linux-gnu.zip yazi-x86_64-unknown-linux-gnu)
            rm -rf /tmp/yz
            ;;
    esac
    return 0
}

yazi_mock_curl_no_sha256() {
    case "$*" in
        *releases/latest*)
            echo '{"tag_name":"v0.4.0"}'
            ;;
        *yazi-x86_64-unknown-linux-gnu.zip.sha256*)
            return 1
            ;;
        *yazi-x86_64-unknown-linux-gnu.zip)
            mkdir -p /tmp/yz/yazi-x86_64-unknown-linux-gnu
            printf 'yazi-binary\n' > /tmp/yz/yazi-x86_64-unknown-linux-gnu/yazi
            printf 'ya-binary\n' > /tmp/yz/yazi-x86_64-unknown-linux-gnu/ya
            (cd /tmp/yz && zip -q -r /tmp/yazi-x86_64-unknown-linux-gnu.zip yazi-x86_64-unknown-linux-gnu)
            rm -rf /tmp/yz
            ;;
    esac
    return 0
}

@test "_install_yazi_prebuilt: installs with valid checksum" {
    which zip 2>/dev/null || skip "zip not installed"
    _curl() { yazi_mock_curl "$@"; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _install_yazi_prebuilt
    assert_success
    assert_output --partial "SHA256 verified"
    assert_output --partial "Installed yazi v0.4.0 (prebuilt)"
    assert [ -f "$HOME/.local/bin/yazi" ]
    assert [ -f "$HOME/.local/bin/ya" ]
    assert [ ! -f /tmp/yazi-x86_64-unknown-linux-gnu.zip ]
}

@test "_install_yazi_prebuilt: warns and continues when no checksum file" {
    which zip 2>/dev/null || skip "zip not installed"
    _curl() { yazi_mock_curl_no_sha256 "$@"; }
    export -f _curl
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _install_yazi_prebuilt
    assert_success
    assert_output --partial "WARNING: No checksum file"
    assert_output --partial "Installed yazi v0.4.0 (prebuilt)"
    assert [ -f "$HOME/.local/bin/yazi" ]
    assert [ -f "$HOME/.local/bin/ya" ]
}

# ── _add_or_skip dispatching ────────────────────────────────────

_add_or_skip() {
    local pkg="$1"
    if _is_deactivated "$pkg"; then
        echo "  Skipping $pkg (deactivated)"
        return
    fi
    if "add_$pkg"; then
        _clear_problematic "$pkg"
    else
        echo "  Warning: $pkg: install failed, marked as problematic"
        _mark_problematic "$pkg"
        return 1
    fi
}

@test "_add_or_skip: calls add_ function for active package" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    _curl() { echo '{"tag_name":"v0.14.0"}'; }
    export -f _curl
    run _add_or_skip "dive"
    assert_success
    assert_output --partial "Add external package: dive"
}

@test "_add_or_skip: skips deactivated package" {
    mkdir -p "$PENNYKIT_HOME/configs"
    echo "dive" > "$PENNYKIT_HOME/configs/extern.skip"
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _add_or_skip "dive"
    assert_success
    assert_output --partial "Skipping dive"
}

@test "_add_or_skip: marks nonexistent package as problematic" {
    source "$(dirname "$BATS_TEST_FILENAME")/../../packages/extern.packages"
    run _add_or_skip "nonexistent"
    assert_failure
    assert_output --partial "install failed"
    assert [ -f "$PENNYKIT_HOME/configs/extern.problematic" ]
    run cat "$PENNYKIT_HOME/configs/extern.problematic"
    assert_output "nonexistent"
}

# ── _update_or_skip (from lib/cmd_extern.sh) ─────────────────────

setup_update_or_skip() {
    source "$(dirname "$BATS_TEST_FILENAME")/../../lib/helpers.sh"
    eval "$(sed -n '/^_update_or_skip/,/^}/p' "$(dirname "$BATS_TEST_FILENAME")/../../lib/cmd_extern.sh")"
}

@test "_update_or_skip: skips deactivated package" {
    setup_update_or_skip
    _is_deactivated() { return 0; }
    export -f _is_deactivated
    run _update_or_skip "anypkg"
    assert_success
    assert_output --partial "Skipping anypkg"
}

@test "_update_or_skip: calls add_ when package not installed" {
    setup_update_or_skip
    _is_deactivated() { return 1; }
    add_testpkg() { echo "installing testpkg"; }
    export -f _is_deactivated add_testpkg
    run _update_or_skip "testpkg"
    assert_success
    assert_output --partial "not installed, trying add_testpkg"
    assert_output --partial "installing testpkg"
}

@test "_update_or_skip: calls update_ when package installed" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    echo '#!/bin/bash' > "$BATS_TEST_TMPDIR/bin/installed_pkg"
    chmod +x "$BATS_TEST_TMPDIR/bin/installed_pkg"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    setup_update_or_skip
    _is_deactivated() { return 1; }
    update_installed_pkg() { echo "updating installed_pkg"; }
    export -f _is_deactivated update_installed_pkg
    run _update_or_skip "installed_pkg"
    assert_success
    assert_output --partial "updating installed_pkg"
}

@test "_update_or_skip: marks problematic on failed add" {
    setup_update_or_skip
    _is_deactivated() { return 1; }
    add_failpkg() { return 1; }
    export -f _is_deactivated add_failpkg
    run _update_or_skip "failpkg"
    assert_success
    assert_output --partial "install failed"
    assert_output --partial "marked as problematic"
}

@test "_update_or_skip: marks problematic on failed update" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    echo '#!/bin/bash' > "$BATS_TEST_TMPDIR/bin/update_fail"
    chmod +x "$BATS_TEST_TMPDIR/bin/update_fail"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    setup_update_or_skip
    _is_deactivated() { return 1; }
    update_update_fail() { return 1; }
    export -f _is_deactivated update_update_fail
    run _update_or_skip "update_fail"
    assert_success
    assert_output --partial "update failed"
    assert_output --partial "marked as problematic"
}

@test "_update_or_skip: reports no update function when installed without update_" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    echo '#!/bin/bash' > "$BATS_TEST_TMPDIR/bin/no_update_pkg"
    chmod +x "$BATS_TEST_TMPDIR/bin/no_update_pkg"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    setup_update_or_skip
    _is_deactivated() { return 1; }
    export -f _is_deactivated
    run _update_or_skip "no_update_pkg"
    assert_success
    assert_output --partial "already installed, no update function"
}
