#!/usr/bin/env bash
set -euo pipefail

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykit}"
exec "$PENNYKIT_HOME/bin/pennykit.sh" theme "$@"
