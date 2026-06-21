#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/docker-verify-$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/docker-verify-$TIMESTAMP.summary"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-7200}"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-pennykit:test}"

if [[ -t 1 ]]; then
    BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'
else
    BOLD=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi

PASS="${GREEN}PASS${RESET}"
FAIL="${RED}FAIL${RESET}"
SKIP="${YELLOW}SKIP${RESET}"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR"

TIMESTAMPER="cat"
if command -v ts >/dev/null 2>&1; then
    TIMESTAMPER="ts '[%Y-%m-%d %H:%M:%S]'"
fi

exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${CYAN}=== Pennykit Docker Install Verification ===${RESET}"
echo "Log: $LOG_FILE"
echo "Build timeout: ${BUILD_TIMEOUT}s"
echo ""

echo -e "${BOLD}Phase 0: Build image (target=runtime)${RESET}"

set +e
timeout "$BUILD_TIMEOUT" \
    sudo docker build \
        --progress=plain \
        -f Dockerfile.apt \
        -t "$DOCKER_IMAGE_NAME" \
        . 2>&1 \
    | eval "$TIMESTAMPER" \
    | tee -a "$LOG_FILE"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

if [[ $BUILD_EXIT -ne 0 ]]; then
    echo -e "${RED}Build failed (exit $BUILD_EXIT) -- aborting verification${RESET}"
    exit 2
fi
echo -e "${PASS} Build successful"
echo ""

CONTAINER_NAME="pennykit-verify-$TIMESTAMP"

echo -e "${BOLD}Starting container...${RESET}"
sudo docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
sudo docker run -d --name "$CONTAINER_NAME" "$DOCKER_IMAGE_NAME" sleep 300 2>&1 | tail -1

DOCKER_EXEC="sudo docker exec -u user -w /home/user $CONTAINER_NAME bash -c"

check() {
    local label="$1"
    local cmd="$2"

    if $DOCKER_EXEC "$cmd" 2>&1; then
        echo -e "  ${PASS} $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  ${FAIL} $label"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_bin() {
    local label="$1"
    check "binary: $label" "command -v $label && ($label --version 2>&1 || $label -V 2>&1 || $label -version 2>&1 || true) | head -1"
}

echo -e "${BOLD}Phase 1: Core CLI${RESET}"
echo ""

check "pennykit binary exists" "[[ -x \$PENNYKIT_HOME/bin/pennykit ]]"
check "pennykit status runs" "\$PENNYKIT_HOME/bin/pennykit status"
check "pennykit doctor runs" "\$PENNYKIT_HOME/bin/pennykit doctor"
check "pennykit theme shows current" "\$PENNYKIT_HOME/bin/pennykit theme"
check "PENNYKIT_HOME is set" "[[ -n \"\$PENNYKIT_HOME\" ]]"
check "PENNYKIT_HOME directory exists" "[[ -d \"\$PENNYKIT_HOME\" ]]"

echo ""
echo -e "${BOLD}Phase 2: Binary presence${RESET}"
echo ""

for bin in nvim git rg fzf tmux lazygit bat lf jq zoxide python3 node npm pipx make gcc delta glow lsd fd chafa tig; do
    check_bin "$bin"
done

echo ""
echo -e "${BOLD}Phase 3: External packages${RESET}"
echo ""

for bin in go vivid yazi tree-sitter lazydocker; do
    check_bin "$bin"
done

echo ""
echo -e "${BOLD}Phase 4: Configuration${RESET}"
echo ""

check "nvim config symlink" "readlink -f ~/.config/nvim | grep -q nvim-starter"
check "tmux config symlink" "readlink -f ~/.tmux.conf | grep -q tmux"
check "bat config symlink" "readlink -f ~/.config/bat/config | grep -q bat"
check "lazygit config symlink" "readlink -f ~/.config/lazygit/config.yml | grep -q lazygit"
check "theme conf exists" "[[ -f \$PENNYKIT_HOME/configs/theme.conf ]]"
check "theme files exist" "ls \$PENNYKIT_HOME/configs/themes/*.conf 2>/dev/null | wc -l | grep -q [1-9]"
check "shell exports file" "[[ -f ~/.pennykit/pennykit_shell.exports ]]"
check "EDITOR set to nvim" "echo \"\$EDITOR\" | grep -q nvim"

echo ""
echo -e "${BOLD}Phase 5: Neovim${RESET}"
echo ""

check "nvim --headless starts" "nvim --headless -c 'qa' 2>&1"
check "Lazy plugin manager directory" "[[ -d ~/.local/share/nvim/lazy ]]"

echo ""
echo -e "${BOLD}Phase 6: Package managers${RESET}"
echo ""

check "dpkg shows installed packages" "dpkg -l 2>/dev/null | grep -c '^ii' | awk '{print \$1}'"
check "pip3 works" "pip3 --version"
check "npm global list" "npm list -g --depth=0 2>/dev/null | head -5"

echo ""
echo -e "${BOLD}Cleaning up...${RESET}"
sudo docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo ""
echo -e "${BOLD}=== Results ===${RESET}"
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
echo "  ${PASS}: $PASS_COUNT"
echo "  ${FAIL}: $FAIL_COUNT"
if [[ $SKIP_COUNT -gt 0 ]]; then
    echo "  ${SKIP}: $SKIP_COUNT"
fi
echo "  Total: $TOTAL"
echo ""
echo "Full log: $LOG_FILE"
echo "Summary: $SUMMARY_FILE"

cp "$LOG_FILE" "$SUMMARY_FILE" 2>/dev/null || true

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${RESET}"
    exit 0
else
    echo -e "${RED}$FAIL_COUNT check(s) failed${RESET}"
    exit 1
fi
