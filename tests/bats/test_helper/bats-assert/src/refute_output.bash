refute_output() {
  __refute_stream "$@"
}

refute_stderr() {
  __refute_stream "$@"
}

__refute_stream() {
  local -r caller=${FUNCNAME[1]}
  local -r stream_type=${caller/refute_/}
  local -i is_mode_partial=0
  local -i is_mode_regexp=0
  local -i is_mode_empty=0
  local -i use_stdin=0

  if [[ ${stream_type} == "output" ]]; then
    : "${output?}"
  elif [[ ${stream_type} == "stderr" ]]; then
    : "${stderr?}"
  else
    :
  fi
  local -r stream="${!stream_type}"

  if (( $# == 0 )); then
    is_mode_empty=1
  fi

  while (( $# > 0 )); do
    case "$1" in
    -p|--partial) is_mode_partial=1; shift ;;
    -e|--regexp) is_mode_regexp=1; shift ;;
    -|--stdin) use_stdin=1; shift ;;
    --) shift; break ;;
    *) break ;;
    esac
  done

  if (( is_mode_partial )) && (( is_mode_regexp )); then
    echo "\`--partial' and \`--regexp' are mutually exclusive" \
    | batslib_decorate "ERROR: ${caller}" \
    | fail
    return $?
  fi

  local unexpected
  if (( use_stdin )); then
    unexpected="$(cat -)"
  else
    unexpected="${1-}"
  fi

  if (( is_mode_regexp == 1 )); then
    __check_is_valid_regex "$unexpected" "$caller" || return 1
  fi

  if (( is_mode_empty )); then
    if [ -n "${stream}" ]; then
      batslib_print_kv_single_or_multi 6 \
      "${stream_type}" "${stream}" \
      | batslib_decorate "${stream_type} non-empty, but expected no ${stream_type}" \
      | fail
    fi
  elif (( is_mode_regexp )); then
    if [[ ${stream} =~ $unexpected ]]; then
      batslib_print_kv_single_or_multi 6 \
      'regexp'  "$unexpected" \
      "${stream_type}" "${stream}" \
      | batslib_decorate "regular expression should not match ${stream_type}" \
      | fail
    fi
  elif (( is_mode_partial )); then
    if [[ ${stream} == *"$unexpected"* ]]; then
      batslib_print_kv_single_or_multi 9 \
      'substring' "$unexpected" \
      "${stream_type}" "${stream}" \
      | batslib_decorate "${stream_type} should not contain substring" \
      | fail
    fi
  else
    if [[ ${stream} == "$unexpected" ]]; then
      batslib_print_kv_single_or_multi 6 \
      "${stream_type}" "${stream}" \
      | batslib_decorate "${stream_type} equals, but it was expected to differ" \
      | fail
    fi
  fi
}
