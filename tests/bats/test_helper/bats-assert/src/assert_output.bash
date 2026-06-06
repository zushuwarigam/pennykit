assert_output() {
  __assert_stream "$@"
}

assert_stderr() {
  __assert_stream "$@"
}

__assert_stream() {
  local -r caller=${FUNCNAME[1]}
  local -r stream_type=${caller/assert_/}
  local -i is_mode_partial=0
  local -i is_mode_regexp=0
  local -i is_mode_nonempty=0
  local -i use_stdin=0

  if [[ ${stream_type} == "output" ]]; then
    : "${output?}"
  elif [[ ${stream_type} == "stderr" ]]; then
    : "${stderr?}"
  else
    echo "Unexpected call to \`${FUNCNAME[0]}\`
Did you mean to call \`assert_output\` or \`assert_stderr\`?" |
      batslib_decorate "ERROR: ${FUNCNAME[0]}" |
      fail
    return $?
  fi
  local -r stream="${!stream_type}"

  if (( $# == 0 )); then
    is_mode_nonempty=1
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

  local expected
  if (( use_stdin )); then
    expected="$(cat -)"
  else
    expected="${1-}"
  fi

  if (( is_mode_nonempty )); then
    if [ -z "$stream" ]; then
      echo "expected non-empty $stream_type, but $stream_type was empty" \
      | batslib_decorate "no $stream_type" \
      | fail
    fi
  elif (( is_mode_regexp )); then
    if ! __check_is_valid_regex "$expected" "$caller"; then
      return 1
    elif ! [[ $stream =~ $expected ]]; then
      batslib_print_kv_single_or_multi 6 \
      'regexp'  "$expected" \
      "$stream_type" "$stream" \
      | batslib_decorate "regular expression does not match $stream_type" \
      | fail
    fi
  elif (( is_mode_partial )); then
    if [[ $stream != *"$expected"* ]]; then
      batslib_print_kv_single_or_multi 9 \
      'substring' "$expected" \
      "$stream_type"    "$stream" \
      | batslib_decorate "$stream_type does not contain substring" \
      | fail
    fi
  else
    if [[ $stream != "$expected" ]]; then
      batslib_print_kv_single_or_multi 8 \
      'expected' "$expected" \
      'actual'   "$stream" \
      | batslib_decorate "$stream_type differs" \
      | fail
    fi
  fi
}
