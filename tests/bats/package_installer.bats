load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    export PENNYKIT_HOME="$BATS_TEST_TMPDIR/.pennykit"
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_OS_ID=1
    mkdir -p "$PENNYKIT_HOME"/{packages,scripts/install,lib}

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

    INSTALLER="$PENNYKIT_HOME/../scripts/install/package_installer.sh"
    if [[ ! -f "$INSTALLER" ]]; then
        INSTALLER="$(dirname "$BATS_TEST_FILENAME")/../../scripts/install/package_installer.sh"
    fi

    cp "$(dirname "$BATS_TEST_FILENAME")/../../scripts/install/package_installer.sh" "$PENNYKIT_HOME/scripts/install/package_installer.sh"
    cp "$(dirname "$BATS_TEST_FILENAME")/../../scripts/install/check_system.sh" "$PENNYKIT_HOME/scripts/install/check_system.sh" 2>/dev/null || true
}

@test "package_installer: dry-run prints commands without executing" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "DRY-RUN"
}

@test "package_installer: sources apt.default and processes layers" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "DRY-RUN"
}

@test "package_installer: skips deactivated packages" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    mkdir -p "$PENNYKIT_HOME/configs"
    echo "dive" > "$PENNYKIT_HOME/configs/extern.skip"
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
}

@test "package_installer: rootless creates local directories" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    local rootless_dir="$BATS_TEST_TMPDIR/rootless-local"
    export PENNYKIT_LOCAL_DIR="$rootless_dir"
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert [ -d "$rootless_dir/bin" ]
    assert [ -d "$rootless_dir/opt" ]
    assert [ -d "$rootless_dir/go" ]
}

@test "package_installer: rootless skips apt commands" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "ROOTLESS"
    assert_output --partial "Skipping apt install"
}

@test "package_installer: rootless overrides dry-run for apt" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    export PENNYKIT_LOCAL_DIR="$BATS_TEST_TMPDIR/rootless-local"
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] pipx install poetry black"
}

@test "package_installer: processes pipx admin packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=ADMIN
    cat > "$PENNYKIT_HOME/packages/pipx.admin" << 'EOF'
PENNYKIT_PIPX_ADMIN=(httpie)
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] pipx install httpie"
}

@test "package_installer: processes pipx pentest packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=PENTEST
    cat > "$PENNYKIT_HOME/packages/pipx.pentest" << 'EOF'
PENNYKIT_PIPX_PENTEST=(sqlmap)
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    # "common" should appear only once
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "[DRY-RUN] npm install -g tree-sitter-cli"
}

@test "package_installer: pins tree-sitter-cli on bookworm (glibc 2.36 incompat)" {
    # tree-sitter-cli >= 0.25.0 requires glibc >= 2.39 (GLIBC_2.39 not found),
    # which bookworm/older do not provide; only trixie gets latest.
    cp "$(dirname "$BATS_TEST_FILENAME")/../../packages/npm.default" "$PENNYKIT_HOME/packages/npm.default"
    export PENNYKIT_OS_VERSION_CODENAME=bookworm
    run bash -c 'source "$PENNYKIT_HOME/packages/npm.default" && printf "%s\n" "${PENNYKIT_NPM_DEFAULT[@]}"'
    assert_success
    assert_output "tree-sitter-cli@0.24.7"

    export PENNYKIT_OS_VERSION_CODENAME=trixie
    run bash -c 'source "$PENNYKIT_HOME/packages/npm.default" && printf "%s\n" "${PENNYKIT_NPM_DEFAULT[@]}"'
    assert_success
    assert_output "tree-sitter-cli"
}

@test "package_installer: processes npm dev packages in dry-run" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEV
    mkdir -p "$PENNYKIT_HOME/packages"
    cat > "$PENNYKIT_HOME/packages/npm.dev" << 'EOF'
PENNYKIT_NPM_DEV=(typescript)
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
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
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "pipx install poetry"
    assert_output --partial "npm install typescript"
}

# ── regression fixes ────────────────────────────────────────────

@test "package_installer: apt-get failure records failed package and does not abort install" {
    # Mock sudo + apt-get so a failing apt install runs through the real (non dry-run, non rootless) path
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/sudo" << 'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-get" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  update|upgrade|clean) exit 0 ;;
  install)
    echo "E: Unable to locate package bogus" >&2
    exit 1
    ;;
  *)
    echo "E: unexpected apt-get args: $*" >&2
    exit 1
    ;;
esac
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo" "$BATS_TEST_TMPDIR/bin/apt-get"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(bogus)
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    # apt stderr is surfaced
    assert_output --partial "E: Unable to locate package bogus"
    # failed package is recorded in the summary instead of silently passing
    assert_output --partial "Failed: 1 packages (bogus)"
}

@test "package_installer: unknown PENNYKIT_PACKAGE_SET errors out with valid values" {
    export PENNYKIT_PACKAGE_SET=bogus
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_failure
    assert_output --partial "unknown PENNYKIT_PACKAGE_SET"
    assert_output --partial "Valid values: DEFAULT, ADMIN, DEV, PENTEST, ALL"
}

@test "package_installer: missing add_ function is reported clearly instead of command not found" {
    export PENNYKIT_DRY_RUN=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EOF'
PENNYKIT_EXTERN_DEFAULT=(nope)
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "no add_nope function defined"
    assert_output --partial "package not registered in packages/extern.packages"
    refute_output --partial "command not found"
    assert_output --partial "Failed: 1 packages (nope)"
}

# ── apt fallback for unavailable packages ────────────────────────

@test "apt: unavailable packages fall back to GitHub-release installer" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/sudo" << 'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-get" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  update|upgrade|clean) exit 0 ;;
  install)
    echo "E: Unable to locate package bogus" >&2
    exit 1
    ;;
  *)
    echo "E: unexpected apt-get args: $*" >&2
    exit 1
    ;;
esac
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-cache" << 'EOF'
#!/usr/bin/env bash
echo "bogus:"
echo "  Installed: (none)"
echo "  Candidate: (none)"
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo" "$BATS_TEST_TMPDIR/bin/apt-get" "$BATS_TEST_TMPDIR/bin/apt-cache"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(bogus)
EOF
    cat > "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
declare -A _ROOTLESS_APT
_apt_rootless_bogus() { echo "INSTALLING bogus via fallback"; }
_ROOTLESS_APT[bogus]=_apt_rootless_bogus
EOF
    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EOF'
PENNYKIT_EXTERN_DEFAULT=()
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "INSTALLING bogus via fallback"
    assert_output --partial "Installed: 1 packages"
    refute_output --partial "Failed: 1 packages (bogus)"
}

@test "apt: unavailable package without fallback is recorded as failed" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/sudo" << 'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-get" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  update|upgrade|clean) exit 0 ;;
  install)
    echo "E: Unable to locate package" >&2
    exit 1
    ;;
  *)
    echo "E: unexpected apt-get args: $*" >&2
    exit 1
    ;;
esac
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-cache" << 'EOF'
#!/usr/bin/env bash
echo "Candidate: (none)"
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo" "$BATS_TEST_TMPDIR/bin/apt-get" "$BATS_TEST_TMPDIR/bin/apt-cache"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(bogus nopkg)
EOF
    cat > "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
declare -A _ROOTLESS_APT
_apt_rootless_bogus() { echo "INSTALLING bogus via fallback"; }
_ROOTLESS_APT[bogus]=_apt_rootless_bogus
EOF
    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EOF'
PENNYKIT_EXTERN_DEFAULT=()
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "INSTALLING bogus via fallback"
    assert_output --partial "Installed: 1 packages"
    assert_output --partial "Failed: 1 packages (nopkg)"
}

@test "apt: available package is not mistaken for missing when apt-cache writes a long version table" {
    # Regression: _apt_available used `grep -q`, which exits at the first match and
    # closes the pipe. Under `set -o pipefail`, apt-cache then dies with SIGPIPE (141)
    # mid-write and the pipeline reports failure even for AVAILABLE packages, wrongly
    # triggering the GitHub fallback. The mock below emits a candidate line followed by
    # ~200KB of version-table filler (> 64KB pipe buffer) so the writer is guaranteed
    # to be in flight when grep -q exits — deterministically reproducing the SIGPIPE race.
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/sudo" << 'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-get" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  update|upgrade|clean) exit 0 ;;
  install)
    echo "E: Unable to locate package bat" >&2
    exit 1
    ;;
  *)
    echo "E: unexpected apt-get args: $*" >&2
    exit 1
    ;;
esac
EOF
    cat > "$BATS_TEST_TMPDIR/bin/apt-cache" << 'EOF'
#!/usr/bin/env bash
echo "bat:"
echo "  Installed: (none)"
echo "  Candidate: 0.22.1-4"
echo "  Version table:"
echo "     0.22.1-4 500"
echo "        500 http://deb.debian.org/debian bookworm/main amd64 Packages"
i=0
while [ "$i" -lt 20000 ]; do echo "        filler-$i"; i=$((i + 1)); done
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo" "$BATS_TEST_TMPDIR/bin/apt-get" "$BATS_TEST_TMPDIR/bin/apt-cache"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    export PENNYKIT_PACKAGE_SET=DEFAULT
    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(bat)
EOF
    cat > "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
declare -A _ROOTLESS_APT
_apt_rootless_bat() { echo "FALLBACK-RAN"; }
_ROOTLESS_APT[bat]=_apt_rootless_bat
EOF
    cat > "$PENNYKIT_HOME/packages/extern.packages" << 'EOF'
PENNYKIT_EXTERN_DEFAULT=()
EOF
    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    # bat is available in apt → the per-package apt install is attempted and fails;
    # the fallback must NOT be reached.
    refute_output --partial "FALLBACK-RAN"
    refute_output --partial "not in apt repos"
    assert_output --partial "Failed: 1 packages (bat)"
}

@test "_rootless_gh_release: handles tags without a v prefix" {
    export PENNYKIT_ROOTLESS=1
    export PENNYKIT_PACKAGE_SET=DEFAULT
    local rootless_dir="$BATS_TEST_TMPDIR/local"
    export PENNYKIT_LOCAL_DIR="$rootless_dir"

    # Fixture: a small gzip tarball containing one executable "custombin"
    mkdir -p "$BATS_TEST_TMPDIR/fix-src"
    printf '#!/usr/bin/env bash\necho custombin\n' > "$BATS_TEST_TMPDIR/fix-src/custombin"
    chmod +x "$BATS_TEST_TMPDIR/fix-src/custombin"
    tar -czf "$BATS_TEST_TMPDIR/fixture.tar.gz" -C "$BATS_TEST_TMPDIR/fix-src" custombin

    # Mock curl: serve the API (tag without "v" prefix) and the release tarball
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/curl" << EOF
#!/usr/bin/env bash
for a in "\$@"; do
  if [[ "\$a" == *api.github.com*releases/latest* ]]; then
    echo '{"tag_name": "0.14.9"}'
    exit 0
  fi
done
prev=""
for a in "\$@"; do
  if [[ "\$prev" == "-o" ]]; then
    cp "$BATS_TEST_TMPDIR/fixture.tar.gz" "\$a"
    exit 0
  fi
  prev="\$a"
done
exit 1
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/curl"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

    cat > "$PENNYKIT_HOME/packages/apt.default" << 'EOF'
PENNYKIT_APT_DEFAULT=(custombin)
EOF
    cp "$(dirname "$BATS_TEST_FILENAME")/../../packages/apt.rootless" "$PENNYKIT_HOME/packages/apt.rootless"
    cat >> "$PENNYKIT_HOME/packages/apt.rootless" << 'EOF'
_apt_rootless_custombin() { _rootless_gh_release "ClementTsang/bottom" "bottom_x86_64-unknown-linux-gnu.tar.gz" "custombin"; }
_ROOTLESS_APT[custombin]=_apt_rootless_custombin
EOF

    run bash "$PENNYKIT_HOME/scripts/install/package_installer.sh" apt
    assert_success
    assert_output --partial "Installing custombin v0.14.9"
    assert [ -x "$rootless_dir/bin/custombin" ]
}
