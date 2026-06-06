assert() {
  if ! "$@"; then
    batslib_print_kv_single 10 'expression' "$*" \
    | batslib_decorate 'assertion failed' \
    | fail
  fi
}
