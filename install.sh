#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$0"

readonly PENNYKIT_REPO_URL="https://github.com/zushuwarigam/pennykit.git"
readonly PENNYKIT_HOME="${HOME}/.pennykit"
readonly PENNYKIT_DEFAULT_BRANCH="kit"

export PENNYKIT_HOME

PENNYKIT_BRANCH="${PENNYKIT_BRANCH:-kit}"

PENNYKIT_FORCE=false
PENNYKIT_PACKAGE_SET=DEFAULT

usage() {
    cat <<EOF
    Usage: $(basename "$0") [options]

    Options:
    -f, --force           Force re‑clone even if $PENNYKIT_HOME already exists
    -p, --package-set     Package set: a/adm/admin, d/dev/develop, p/pen/pentest, all
    -r, --rootless        Rootless mode (skip apt, install to ~/.local/)
    -h, --help            Show this help message and exit

    Environment:
    PENNYKIT_BRANCH        Branch to clone (default: kit). If that branch is gone
                           from the remote, the installer warns and falls back to
                           the remote's default branch.

EOF
exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force) PENNYKIT_FORCE=true; shift ;;
        -p|--package-set)
            PENNYKIT_PACKAGE_SET="$2"
            case "$PENNYKIT_PACKAGE_SET" in
                a|adm|admin) PENNYKIT_PACKAGE_SET=ADMIN ;;
                d|dev|develop) PENNYKIT_PACKAGE_SET=DEV ;;
                p|pen|pentest) PENNYKIT_PACKAGE_SET=PENTEST;;
                all) PENNYKIT_PACKAGE_SET=ALL;;
                *) usage ;;
            esac
            shift
            ;;
        -r|--rootless) PENNYKIT_ROOTLESS=true; shift ;;
        -h|--help)  usage ;;
        *)          shift ;;   # unknown options are ignored – they will be passed through
    esac
done

export PENNYKIT_FORCE
export PENNYKIT_PACKAGE_SET
export PENNYKIT_ROOTLESS

# State of a branch on the remote:
#   0 = exists
#   1 = confirmed missing (branch was deleted / never existed)
#   2 = could not determine (network/auth error) – caller keeps the requested branch
_remote_branch_state() {
    local branch="$1" out rc
    if out=$(git ls-remote --exit-code --heads "$PENNYKIT_REPO_URL" "refs/heads/$branch" 2>/dev/null); then
        if [[ -n "$out" ]]; then
            return 0
        fi
        return 1
    else
        rc=$?
    fi
    # git ls-remote --exit-code exits 2 when no matching ref exists
    [[ $rc -eq 2 ]] && return 1
    return 2
}

# Branch the remote HEAD points at; falls back to the shipped default branch
_remote_default_branch() {
    local out
    out=$(git ls-remote --symref "$PENNYKIT_REPO_URL" HEAD 2>/dev/null) || true
    if [[ "$out" == *"refs/heads/"* ]]; then
        out="${out#*refs/heads/}"
        printf '%s\n' "${out%%[[:space:]]*}"
        return 0
    fi
    printf '%s\n' "$PENNYKIT_DEFAULT_BRANCH"
}

if [[ -d "$PENNYKIT_HOME" ]]; then
    if [[ "$PENNYKIT_FORCE" == "true" ]]; then
        echo "INFO: --force supplied – removing existing $PENNYKIT_HOME ..."
        rm -rf "$PENNYKIT_HOME"
    elif git -C "$PENNYKIT_HOME" rev-parse --git-dir >/dev/null 2>&1; then
        echo "INFO: $PENNYKIT_HOME already exists – using existing copy."
        git -C "$PENNYKIT_HOME" pull --rebase || {
            echo "WARNING: git pull failed – removing and re-cloning ..."
            rm -rf "$PENNYKIT_HOME"
        }
    else
        echo "INFO: $PENNYKIT_HOME exists but is not a git repo – removing and re-cloning ..."
        rm -rf "$PENNYKIT_HOME"
    fi
fi

if [[ ! -d "$PENNYKIT_HOME" ]]; then
    branch_state=0
    _remote_branch_state "$PENNYKIT_BRANCH" || branch_state=$?
    if [[ $branch_state -eq 1 ]]; then
        fallback_branch="$(_remote_default_branch)"
        echo "WARNING: branch '$PENNYKIT_BRANCH' no longer exists in $PENNYKIT_REPO_URL." >&2
        echo "         Falling back to '$fallback_branch'." >&2
        echo "         If this is unexpected, check the PENNYKIT_BRANCH environment variable." >&2
        PENNYKIT_BRANCH="$fallback_branch"
    fi

    echo "Cloning PennyKit($PENNYKIT_BRANCH) from $PENNYKIT_REPO_URL into $PENNYKIT_HOME ..."
    if ! git clone --depth=1 --branch="$PENNYKIT_BRANCH" "$PENNYKIT_REPO_URL" "$PENNYKIT_HOME"; then
        echo "ERROR: Failed to clone repository." >&2
        exit 1
    fi
else
    echo "Skipping clone – repository already present."
fi

CURRENT_DIR="$(pwd)"
cd "$PENNYKIT_HOME"

echo "Sourcing and executing pennykit_install.sh ..."
# shellcheck disable=SC1091
source ./pennykit_install.sh

cd "$CURRENT_DIR"
