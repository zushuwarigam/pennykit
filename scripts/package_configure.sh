#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$0"

cd "$PENNYKIT_HOME"

find configs -maxdepth 1 -mindepth 1 -name "config.*" -exec bash -c 'source "$1"' _ {} \;
