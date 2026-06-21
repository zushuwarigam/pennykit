# Docker Install Test Script — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `scripts/test_docker_install.sh` — a robust script to run the full Pennykit Docker multi-stage build with real-time log analysis.

**Architecture:** Single bash script using Docker's `--progress=plain` output, piped through optional `ts` for timestamps, `tee` for capture, then grep-based post-build analysis.

**Tech Stack:** bash, Docker, moreutils (optional)

---

### Task 1: Create `scripts/test_docker_install.sh`

**Files:**
- Create: `scripts/test_docker_install.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test Docker install for Pennykit — runs full multi-stage build with
# real-time log analysis. Usage: sudo ./scripts/test_docker_install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/docker-install-$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/docker-install-$TIMESTAMP.summary"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-7200}"

mkdir -p "$LOG_DIR"

# Detect ts (moreutils) for timestamps
TIMESTAMPER="cat"
if command -v ts >/dev/null 2>&1; then
    TIMESTAMPER="ts '[%Y-%m-%d %H:%M:%S]'"
fi

cd "$PROJECT_DIR"

echo "=== Pennykit Docker Install Test ==="
echo "Log: $LOG_FILE"
echo "Target: runtime (full multi-stage build: os -> pkgs -> nvim -> runtime)"
echo "Timeout: ${BUILD_TIMEOUT}s"
echo ""

# Build
timeout "$BUILD_TIMEOUT" \
    sudo docker build \
        --progress=plain \
        -f Dockerfile.apt \
        -t pennykit:test \
        . 2>&1 \
    | eval "$TIMESTAMPER" \
    | tee "$LOG_FILE"

BUILD_EXIT=${PIPESTATUS[0]}

echo ""
echo "=== Build Summary ===" > "$SUMMARY_FILE"
{
    echo "Build exit code: $BUILD_EXIT"
    if [[ $BUILD_EXIT -eq 0 ]]; then
        echo "Status: SUCCESS"
    elif [[ $BUILD_EXIT -eq 124 ]]; then
        echo "Status: TIMEOUT (${BUILD_TIMEOUT}s exceeded)"
    else
        echo "Status: FAILED"
    fi
} | tee -a "$SUMMARY_FILE"

# --- Layer timing ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Layer Timing ---" | tee -a "$SUMMARY_FILE"
grep -E '#[0-9]+ DONE [0-9.]+s' "$LOG_FILE" \
    | sed 's/^/[Docker] /' \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

# --- Package install timing ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Package Install Lines ---" | tee -a "$SUMMARY_FILE"
grep -E '(apt-get install|apt install)' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

# --- Errors ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Errors (max 20) ---" | tee -a "$SUMMARY_FILE"
grep -in 'error' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

# --- Warnings ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Warnings (max 20) ---" | tee -a "$SUMMARY_FILE"
grep -in 'warning' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

# --- Nvim Lazy install ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Neovim Lazy Install ---" | tee -a "$SUMMARY_FILE"
grep -E '(Lazy|Lazy\.locked|plugins|nvim)' "$LOG_FILE" \
    | head -10 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

# --- Total duration ---
echo "" | tee -a "$SUMMARY_FILE"
echo "--- Total Build Duration ---" | tee -a "$SUMMARY_FILE"
{
    echo -n "Start: "
    head -1 "$LOG_FILE" 2>/dev/null || echo "(log empty)"
    echo -n "End:   "
    tail -1 "$LOG_FILE" 2>/dev/null || echo "(log empty)"
} | tee -a "$SUMMARY_FILE"

echo "" | tee -a "$SUMMARY_FILE"
echo "Summary saved to: $SUMMARY_FILE" | tee -a "$SUMMARY_FILE"
echo "" | tee -a "$SUMMARY_FILE"

exit "$BUILD_EXIT"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/test_docker_install.sh
```

- [ ] **Step 3: Run shellcheck**

```bash
shellcheck --severity=style scripts/test_docker_install.sh
```

Expected: clean exit, no issues.

- [ ] **Step 4: Verify script runs without Docker (graceful failure check)**

```bash
bash scripts/test_docker_install.sh 2>&1 || true
```

Expected: errors about "sudo: docker: command not found" or "sudo: unable to resolve host" — but the script should exit with a non-zero code cleanly, not with a bash syntax error.

- [ ] **Step 5: Commit**

```bash
git add scripts/test_docker_install.sh docs/superpowers/specs/2026-06-21-docker-install-test-script-design.md docs/superpowers/plans/2026-06-21-docker-install-test-script.md
git commit -m "feat: add Docker install test script with real-time log analysis"
```
