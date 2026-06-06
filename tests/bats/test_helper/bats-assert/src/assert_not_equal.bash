assert_not_equal() {
  if [[ "$1" == "$2" ]]; then
    batslib_print_kv_single_or_multi 10 \
    'unexpected' "$2" \
    'actual'     "$1" \
    | batslib_decorate 'values should not be equal' \
    | fail
  fi
}
