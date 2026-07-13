#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$HERE")")"

echo "=========================================="
echo " PennyKit Test Suite"
echo "=========================================="
echo ""

FAILED=0

# ── ShellCheck ──────────────────────────────────────────────────
echo "=== [1/4] ShellCheck ==="
if command -v shellcheck &>/dev/null; then
    find "$PROJECT_DIR" -name "*.sh" -o -name "*.bash" \
        | grep -v tests/ \
        | xargs shellcheck --severity=style || { echo "  shellcheck found issues"; FAILED=$((FAILED + 1)); }
    echo "  done"
else
    echo "  SKIP: shellcheck not installed"
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
fi
echo ""

# ── BATS ────────────────────────────────────────────────────────
echo "=== [3/4] BATS ==="
if command -v bats &>/dev/null; then
    bats "$PROJECT_DIR/tests/bats/"*.bats || FAILED=$((FAILED + 1))
else
    echo "  SKIP: bats not installed (install with: npm install -g bats)"
fi
echo ""

# ── pytest ──────────────────────────────────────────────────────
echo "=== [4/4] pytest ==="
if command -v python3 &>/dev/null && python3 -c "import pytest" &>/dev/null; then
    python3 -m pytest "$PROJECT_DIR/tests/python/" -v -m "not slow" || FAILED=$((FAILED + 1))
else
    echo "  SKIP: pytest not installed (install with: pip install pytest)"
fi
echo ""

# ── Summary ─────────────────────────────────────────────────────
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo " All tests passed!"
else
    echo " $FAILED test suite(s) reported failures."
fi
echo "=========================================="
exit $FAILED
