#!/usr/bin/env bash
set -euo pipefail
printf "### %s\n" "$0"

cd "$PENNYKIT_HOME"

find configs -mindepth 1 -name "config.*" -exec bash -c '
  source "$PENNYKIT_HOME/lib/helpers.sh" 2>/dev/null || true
  source "$0"
' {} \;
