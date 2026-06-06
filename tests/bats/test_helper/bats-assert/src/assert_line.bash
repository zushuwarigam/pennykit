assert_line() {
  __assert_line "$@"
}

assert_stderr_line() {
  __assert_line "$@"
}

__assert_line() {
  local -r caller=${FUNCNAME[1]}
  local -i is_match_line=0
  local -i is_mode_partial=0
  local -i is_mode_regexp=0

  if [[ "${caller}" == "assert_line" ]]; then
    : "${lines?}"
    local -ar stream_lines=("${lines[@]}")
    local -r stream_type=output
  elif [[ "${caller}" == "assert_stderr_line" ]]; then
    : "${stderr_lines?}"
    local -ar stream_lines=("${stderr_lines[@]}")
    local -r stream_type=stderr
  else
    echo "Unexpected call to \`${FUNCNAME[0]}\`
Did you mean to call \`assert_line\` or \`assert_stderr_line\`?" \
    | batslib_decorate "ERROR: ${FUNCNAME[0]}" \
    | fail
    return $?
  fi

  while (( $# > 0 )); do
    case "$1" in
    -n|--index)
      if (( $# < 2 )) || ! [[ $2 =~ ^-?([0-9]|[1-9][0-9]+)$ ]]; then
        echo "\`--index' requires an integer argument: \`$2'" \
        | batslib_decorate "ERROR: ${caller}" \
        | fail
        return $?
      fi
      is_match_line=1
      local -ri idx="$2"
      shift 2
      ;;
    -p|--partial) is_mode_partial=1; shift ;;
    -e|--regexp) is_mode_regexp=1; shift ;;
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

  local -r expected="$1"

  if (( is_mode_regexp == 1 )); then
    __check_is_valid_regex "$expected" "$caller" || return 1
  fi

  if (( is_match_line )); then
    if (( is_mode_regexp )); then
      if ! [[ ${stream_lines[$idx]} =~ $expected ]]; then
        batslib_print_kv_single 6 \
        'index' "$idx" \
        'regexp' "$expected" \
        'line'  "${stream_lines[$idx]}" \
        | batslib_decorate 'regular expression does not match line' \
        | fail
      fi
    elif (( is_mode_partial )); then
      if [[ ${stream_lines[$idx]} != *"$expected"* ]]; then
        batslib_print_kv_single 9 \
        'index'     "$idx" \
        'substring' "$expected" \
        'line'      "${stream_lines[$idx]}" \
        | batslib_decorate 'line does not contain substring' \
        | fail
      fi
    else
      if [[ ${stream_lines[$idx]} != "$expected" ]]; then
        batslib_print_kv_single 8 \
        'index'    "$idx" \
        'expected' "$expected" \
        'actual'   "${stream_lines[$idx]}" \
        | batslib_decorate 'line differs' \
        | fail
      fi
    fi
  else
    if (( is_mode_regexp )); then
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        [[ ${stream_lines[$idx]} =~ $expected ]] && return 0
      done
      { local -ar single=( 'regexp' "$expected" )
        local -ar may_be_multi=( "${stream_type}" "${!stream_type}" )
        local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } \
      | batslib_decorate "no ${stream_type} line matches regular expression" \
      | fail
    elif (( is_mode_partial )); then
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        [[ ${stream_lines[$idx]} == *"$expected"* ]] && return 0
      done
      { local -ar single=( 'substring' "$expected" )
        local -ar may_be_multi=( "${stream_type}" "${!stream_type}" )
        local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } \
      | batslib_decorate "no ${stream_type} line contains substring" \
      | fail
    else
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        [[ ${stream_lines[$idx]} == "$expected" ]] && return 0
      done
      { local -ar single=( 'line' "$expected" )
        local -ar may_be_multi=( "${stream_type}" "${!stream_type}" )
        local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
        batslib_print_kv_single "$width" "${single[@]}"
        batslib_print_kv_single_or_multi "$width" "${may_be_multi[@]}"
      } \
      | batslib_decorate "${stream_type} does not contain line" \
      | fail
    fi
  fi
}
