#!/usr/bin/env bash
set -euo pipefail

grep -rnI "pkg.*desc" | sed -E 's/(.*#\s+)(pkg:)(.*)(;\s+)(desc:\s)(.*)/- \3: \6/g' | grep -v "get_packages.sh" | sort -u
