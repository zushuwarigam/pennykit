#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"

do_verify=false
if [[ "${1:-}" == "--verify" ]]; then
    do_verify=true
    shift
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/docker-install-$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/docker-install-$TIMESTAMP.summary"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-7200}"

mkdir -p "$LOG_DIR"

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

set +e
timeout "$BUILD_TIMEOUT" \
    sudo docker build \
        --progress=plain \
        -f Dockerfile.apt \
        -t pennykit:test \
        . 2>&1 \
    | eval "$TIMESTAMPER" \
    | tee "$LOG_FILE"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

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

echo "" | tee -a "$SUMMARY_FILE"
echo "--- Layer Timing ---" | tee -a "$SUMMARY_FILE"
grep -E '#[0-9]+ DONE [0-9.]+s' "$LOG_FILE" \
    | sed 's/^/[Docker] /' \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

echo "" | tee -a "$SUMMARY_FILE"
echo "--- Package Install Lines ---" | tee -a "$SUMMARY_FILE"
grep -E '(apt-get install|apt install)' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

echo "" | tee -a "$SUMMARY_FILE"
echo "--- Errors (max 20) ---" | tee -a "$SUMMARY_FILE"
grep -in 'error' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

echo "" | tee -a "$SUMMARY_FILE"
echo "--- Warnings (max 20) ---" | tee -a "$SUMMARY_FILE"
grep -in 'warning' "$LOG_FILE" \
    | head -20 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

echo "" | tee -a "$SUMMARY_FILE"
echo "--- Neovim Lazy Install ---" | tee -a "$SUMMARY_FILE"
grep -E '(Lazy|Lazy\.locked|plugins|nvim)' "$LOG_FILE" \
    | head -10 \
    | tee -a "$SUMMARY_FILE" || echo "  (none)" | tee -a "$SUMMARY_FILE"

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

if $do_verify && [[ $BUILD_EXIT -eq 0 ]]; then
    echo "=== Launching verification (--verify) ==="
    echo ""
    exec "$SCRIPT_DIR/verify_docker_install.sh"
fi

exit "$BUILD_EXIT"
