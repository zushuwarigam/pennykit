assert_failure() {
  : "${output?}"
  : "${status?}"
  (( $# > 0 )) && local -r expected="$1"
  if (( status == 0 )); then
    { local -ir width=6
      batslib_print_kv_single_or_multi "$width" 'output' "$output"
      if [[ -n "${stderr-}" ]]; then
        batslib_print_kv_single_or_multi "$width" 'stderr' "$stderr"
      fi
    } \
    | batslib_decorate 'command succeeded, but it was expected to fail' \
    | fail
  elif (( $# > 0 )) && (( status != expected )); then
    { local -ir width=8
      batslib_print_kv_single "$width" \
      'expected' "$expected" \
      'actual'   "$status"
      batslib_print_kv_single_or_multi "$width" \
      'output' "$output"
      if [[ -n "${stderr-}" ]]; then
        batslib_print_kv_single_or_multi "$width" 'stderr' "$stderr"
      fi
    } \
    | batslib_decorate 'command failed as expected, but status differs' \
    | fail
  fi
}
