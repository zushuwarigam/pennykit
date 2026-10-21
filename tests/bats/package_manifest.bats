load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    APT_DEFAULT="$REPO_ROOT/packages/apt.default"
    APT_ROOTLESS="$REPO_ROOT/packages/apt.rootless"
    BREW="$REPO_ROOT/packages/brew"
}

# ── apt.default ─────────────────────────────────────────────────

@test "apt.default: DEFAULT tier declares neomutt and khard" {
    run grep -E 'PENNYKIT_APT_DEFAULT\+=\("(neomutt|khard)"\)' "$APT_DEFAULT"
    assert_success
    assert_output --partial '("neomutt")'
    assert_output --partial '("khard")'
}

@test "apt.default: neomutt and khard carry a package-description marker" {
    # The marker format is what scripts/util/get_packages.sh parses.
    local marker="desc:"
    for pkg in neomutt khard; do
        run grep -E "PENNYKIT_APT_DEFAULT\\+=\\(\"$pkg\"\\).*$marker" "$APT_DEFAULT"
        assert_success
    done
}

@test "apt tiers: every entry carries a package-description marker" {
    for tier in default admin dev pentest; do
        run bash -c "grep -E 'PENNYKIT_APT_[A-Z]+=' '$REPO_ROOT/packages/apt.$tier' | grep -cv 'desc:' || true"
        assert_output "0"
    done
}

@test "apt tiers: neomutt and khard are declared exactly once" {
    for pkg in neomutt khard; do
        count=$(grep -rhF "+=(\"$pkg\")" "$REPO_ROOT"/packages/apt.* 2>/dev/null | wc -l)
        [[ "$count" -eq 1 ]]
    done
}

# ── apt.rootless ───────────────────────────────────────────────

@test "apt.rootless: khard has a rootless fallback registered" {
    run grep -E '^_ROOTLESS_APT\[khard\]=_apt_rootless_khard$' "$APT_ROOTLESS"
    assert_success
}

@test "apt.rootless: every registration points to a defined function" {
    run bash -c "source '$APT_ROOTLESS' >/dev/null 2>&1; for k in \"\${!_ROOTLESS_APT[@]}\"; do declare -F \"\${_ROOTLESS_APT[\$k]}\" >/dev/null 2>&1 || echo \"MISSING:\$k\"; done"
    assert_success
    assert_output ""
}

@test "apt.rootless: the khard fallback uses pipx" {
    run bash -c "source '$APT_ROOTLESS' >/dev/null 2>&1; declare -f _apt_rootless_khard"
    assert_success
    assert_output --partial "pipx"
    assert_output --partial "khard"
}

# ── brew ────────────────────────────────────────────────────────

@test "brew: neomutt and khard are listed as available formulas" {
    run grep -E 'PENNYKIT_BREW_DEFAULT\+=\("(neomutt|khard)"\) # \+' "$BREW"
    assert_success
    assert_output --partial '("neomutt")'
    assert_output --partial '("khard")'
}

# ── get_packages.sh ─────────────────────────────────────────────

@test "get_packages.sh: lists neomutt and khard with their descriptions" {
    run bash "$REPO_ROOT/scripts/util/get_packages.sh"
    assert_success
    assert_output --partial "neomutt: "
    assert_output --partial "khard: "
}
