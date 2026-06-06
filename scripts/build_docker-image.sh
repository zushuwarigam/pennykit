#!/usr/bin/env bash
# shellcheck disable=SC1091
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

_readlinkf() { command -v greadlink >/dev/null 2>&1 && greadlink -f "$@" || readlink -f "$@"; }

SCRIPT_DIR="$(cd "$(dirname "$(_readlinkf "$0")")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

CONFIG_FILE="./config"
[[ ! -f "$CONFIG_FILE" ]] && { echo "Error: $CONFIG_FILE not found" >&2; exit 1; }
source "$CONFIG_FILE"

mapfile -t dockerfiles < <(find . -maxdepth 1 -type f -name "Dockerfile.*" | sed 's/\.\///g' | sort)
[[ ${#dockerfiles[@]} -eq 0 ]] && { echo "Error: no Dockerfile.* found" >&2; exit 1; }

echo "Select Dockerfile:"
PS3="Enter your choice: "
select dockerfile in "${dockerfiles[@]}"; do
  if [ -n "$dockerfile" ]; then
    break
  fi
done

target="${1:-runtime}"
tag="${PK_BASE_IMAGE_TAG}"

echo "Building $dockerfile (target=$target) as ${PROJECT_NAME}:${tag} ..."
docker build \
  --build-arg "USER=${USER}" \
  --build-arg "UID=${UID}" \
  --build-arg "PK_BASE_IMAGE_NAME=${PK_BASE_IMAGE_NAME}" \
  --build-arg "PK_BASE_IMAGE_TAG=${PK_BASE_IMAGE_TAG}" \
  --target "$target" \
  -f "$dockerfile" \
  -t "${PROJECT_NAME}:${tag}" \
  .
