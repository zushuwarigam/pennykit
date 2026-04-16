#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$(readlink -f "$0")"

source "./config"

mapfile -t dockerfile < <(find . -maxdepth 1 -type f -name "Dockerfile.*" | sed 's/\.\///g')

PS3="Enter you choice: "
select i in "${dockerfile[@]}"; do
  if [ -n "$i" ]; then
    DOCKERFILE="$i"
    break
  fi
done

# --no-cache \
# --progress=plain \
docker build \
  --build-arg "USER=$USER" \
  --build-arg "UID=$UID" \
  --build-arg "PK_BASE_IMAGE_NAME=$PK_BASE_IMAGE_NAME" \
  --build-arg "PK_BASE_IMAGE_TAG=$PK_BASE_IMAGE_TAG" \
  -f "$DOCKERFILE" \
  -t "${PROJECT_NAME}:${PK_BASE_IMAGE_TAG}" \
  .
