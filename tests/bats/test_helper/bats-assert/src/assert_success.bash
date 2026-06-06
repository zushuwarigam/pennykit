assert_success() {
  : "${output?}"
  : "${status?}"
  if (( status != 0 )); then
    { local -ir width=6
      batslib_print_kv_single "$width" 'status' "$status"
      batslib_print_kv_single_or_multi "$width" 'output' "$output"
      if [[ -n "${stderr-}" ]]; then
        batslib_print_kv_single_or_multi "$width" 'stderr' "$stderr"
      fi
    } \
    | batslib_decorate 'command failed' \
    | fail
  fi
}
