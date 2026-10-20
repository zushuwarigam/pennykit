#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HERE")")"

echo "=========================================="
echo " PennyKit Test Suite"
echo "=========================================="
echo ""

FAILED=0
SKIPPED_TIERS=()

# ── ShellCheck ──────────────────────────────────────────────────
echo "=== [1/4] ShellCheck ==="
if command -v shellcheck &>/dev/null; then
    find "$PROJECT_DIR" \( -name "*.sh" -o -name "*.bash" \) \
        -not -path "$PROJECT_DIR/node_modules/*" -not -path "$PROJECT_DIR/.git/*" \
        | grep -v tests/ \
        | xargs -r shellcheck --severity=style || { echo "  shellcheck found issues"; FAILED=$((FAILED + 1)); }
    echo "  done"
else
    echo "  SKIP: shellcheck not installed"
    SKIPPED_TIERS+=("ShellCheck")
fi
echo ""

# ── hadolint ────────────────────────────────────────────────────
echo "=== [2/4] hadolint ==="
if command -v hadolint &>/dev/null; then
    for df in Dockerfile.apt Dockerfile.brew Dockerfile.dev-debian_bookworm Dockerfile.dev-debian_trixie; do
        echo "  Linting $df ..."
        hadolint "$PROJECT_DIR/$df" || { echo "  hadolint failed on $df"; FAILED=$((FAILED + 1)); }
    done
elif command -v docker &>/dev/null; then
    for df in Dockerfile.apt Dockerfile.brew Dockerfile.dev-debian_bookworm Dockerfile.dev-debian_trixie; do
        echo "  Linting $df (via docker) ..."
        docker run --rm -i hadolint/hadolint < "$PROJECT_DIR/$df" || { echo "  hadolint failed on $df"; FAILED=$((FAILED + 1)); }
    done
else
    echo "  SKIP: neither hadolint nor docker available"
    SKIPPED_TIERS+=("hadolint")
fi
echo ""

# ── BATS ────────────────────────────────────────────────────────
echo "=== [3/4] BATS ==="
if command -v bats &>/dev/null; then
    bats "$PROJECT_DIR/tests/bats/"*.bats || FAILED=$((FAILED + 1))
else
    echo "  SKIP: bats not installed (install with: npm install -g bats)"
    SKIPPED_TIERS+=("BATS")
fi
echo ""

# ── pytest ──────────────────────────────────────────────────────
echo "=== [4/4] pytest ==="
if command -v python3 &>/dev/null && python3 -c "import pytest" &>/dev/null; then
    python3 -m pytest "$PROJECT_DIR/tests/python/" -v -m "not slow" || FAILED=$((FAILED + 1))
else
    echo "  SKIP: pytest not installed (install with: pip install pytest)"
    SKIPPED_TIERS+=("pytest")
fi
echo ""

# ── Summary ─────────────────────────────────────────────────────
echo "=========================================="
if [[ ${#SKIPPED_TIERS[@]} -eq 4 ]]; then
    echo " NO test tools found — nothing was actually tested."
    echo " Install shellcheck, hadolint (or docker), bats, and pytest."
    echo "=========================================="
    exit 1
fi
if [[ $FAILED -eq 0 ]]; then
    echo " All tests passed!"
else
    echo " $FAILED test suite(s) reported failures."
fi
if [[ ${#SKIPPED_TIERS[@]} -gt 0 ]]; then
    echo " Skipped tier(s) (not run): ${SKIPPED_TIERS[*]}"
fi
echo "=========================================="
exit $FAILED
