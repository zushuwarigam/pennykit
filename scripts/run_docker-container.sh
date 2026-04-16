#!/usr/bin/env bash
printf "### %s\n" "$(readlink -f "$0")"

docker run -ti --rm \
  -v "$(pwd)":/workdir \
  -w /workdir \
  pennykit:trixie
