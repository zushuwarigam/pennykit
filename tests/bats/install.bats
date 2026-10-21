load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # install.sh derives its own PENNYKIT_HOME from $HOME — keep the two in sync
    export HOME="$BATS_TEST_TMPDIR/home"
    export PENNYKIT_HOME="$HOME/.pennykit"
    mkdir -p "$HOME"

    INSTALL_SCRIPT="$(dirname "$BATS_TEST_FILENAME")/../../install.sh"

    # Hermetic network: a git shim on PATH that fails clone/rev-parse deterministically
    # so no test ever touches the real remote. The shim forwards nothing to real git.
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<'SHIM'
#!/usr/bin/env bash
case "$*" in
    *clone*)
        echo "fatal: could not read from remote repository." >&2
        exit 128 ;;
    *rev-parse*)
        echo "fatal: not a git repository (or any of the parent directories): .git" >&2
        exit 128 ;;
    *)
        exit 0 ;;
esac
SHIM
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "install: --help shows usage" {
    run bash "$INSTALL_SCRIPT" --help
    assert_success
    assert_output --partial "Usage:"
}

@test "install: -h shows usage" {
    run bash "$INSTALL_SCRIPT" -h
    assert_success
    assert_output --partial "Usage:"
}

@test "install: clone failure surfaces ERROR and nonzero exit" {
    run bash "$INSTALL_SCRIPT"
    assert_failure
    assert_output --partial "Failed to clone repository"
}

@test "install: existing non-repo directory is removed before re-clone" {
    mkdir -p "$PENNYKIT_HOME"
    echo "stale" > "$PENNYKIT_HOME/stale-file"
    run bash "$INSTALL_SCRIPT"
    assert_failure
    assert_output --partial "not a git repo"
    assert_output --partial "Failed to clone repository"
}

@test "install: --force removes existing directory" {
    mkdir -p "$PENNYKIT_HOME"
    echo "stale" > "$PENNYKIT_HOME/stale-file"
    run bash "$INSTALL_SCRIPT" --force
    assert_failure
    assert_output --partial "INFO: --force supplied"
    assert_output --partial "Failed to clone repository"
}

@test "install: accepts -p package set option" {
    run bash "$INSTALL_SCRIPT" -p dev
    # A valid set must proceed past usage parsing (failing later only at the mocked clone)
    assert_output --partial "Cloning PennyKit"
    refute_output --partial "Usage:"
}

@test "install: invalid package set prints usage" {
    run bash "$INSTALL_SCRIPT" -p bogus
    assert_output --partial "Usage:"
}
# Writes a git shim that models a remote whose only branch is $3 (default: kit).
#   $1 = ls-remote exit code for a branch that does not exist (2 = missing, 128 = network error)
#   $2 = clone exit code (0 = clone succeeds and produces a fake checkout)
#   $3 = name of the branch that exists on the remote
write_git_shim() {
    local unknown_rc="$1" clone_rc="$2" remote_branch="${3:-kit}"
    cat > "$BATS_TEST_TMPDIR/bin/git" <<SHIM
#!/usr/bin/env bash
case "\$*" in
    *ls-remote*)
        if [[ "\$*" == *"--symref"* ]]; then
            printf 'ref: refs/heads/${remote_branch}\tHEAD\n'
            exit 0
        fi
        for arg in "\$@"; do
            case "\$arg" in
                refs/heads/${remote_branch})
                    printf 'aaaaaaa\trefs/heads/${remote_branch}\n'
                    exit 0 ;;
            esac
        done
        exit ${unknown_rc} ;;
    *clone*)
        target="\${!#}"
        if [[ ${clone_rc} -eq 0 ]]; then
            mkdir -p "\$target"
            printf 'echo "FAKE INSTALL COMPLETE"\n' > "\$target/pennykit_install.sh"
        fi
        exit ${clone_rc} ;;
    *rev-parse*)
        echo "fatal: not a git repository" >&2
        exit 128 ;;
    *) exit 0 ;;
esac
SHIM
    chmod +x "$BATS_TEST_TMPDIR/bin/git"
}

@test "install: branch deleted upstream falls back to the remote default branch" {
    write_git_shim 2 0 kit
    export PENNYKIT_BRANCH=improve-kit-dev
    run bash "$INSTALL_SCRIPT"
    assert_success
    assert_output --partial "no longer exists"
    assert_output --partial "Falling back to 'kit'"
    assert_output --partial "Cloning PennyKit(kit)"
    assert_output --partial "FAKE INSTALL COMPLETE"
}

@test "install: existing branch is cloned without fallback warning" {
    write_git_shim 2 0 kit
    export PENNYKIT_BRANCH=kit
    run bash "$INSTALL_SCRIPT"
    assert_success
    refute_output --partial "no longer exists"
    assert_output --partial "Cloning PennyKit(kit)"
}

@test "install: unreachable remote keeps the requested branch and reports clone failure" {
    write_git_shim 128 128 kit
    export PENNYKIT_BRANCH=improve-kit-dev
    run bash "$INSTALL_SCRIPT"
    assert_failure
    refute_output --partial "no longer exists"
    assert_output --partial "Cloning PennyKit(improve-kit-dev)"
    assert_output --partial "Failed to clone repository"
}

@test "install: remote default branch is used when the shipped default is gone" {
    write_git_shim 2 0 main
    run bash "$INSTALL_SCRIPT"
    assert_success
    assert_output --partial "Falling back to 'main'"
    assert_output --partial "Cloning PennyKit(main)"
}
