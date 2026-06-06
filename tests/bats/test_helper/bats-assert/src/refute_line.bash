refute_line() {
  __refute_stream_line "$@"
}

refute_stderr_line() {
  __refute_stream_line "$@"
}

__check_is_valid_regex() {
  local -r regex="$1" caller="$2"
  local error
  error=$([[ '' =~ $regex ]] 2>&1)
  if [[ $? == 2 ]]; then
    local err_msg="Invalid extended regular expression: \`$regex'"
    if [[ $error =~ (invalid regular expression .*) ]]; then
      err_msg="${BASH_REMATCH[1]}"
    fi
    echo "$err_msg" \
    | batslib_decorate "ERROR: ${caller}" \
    | fail
  fi
}

__refute_stream_line() {
  local -r caller=${FUNCNAME[1]}
  local -i is_match_line=0
  local -i is_mode_partial=0
  local -i is_mode_regexp=0

  if [[ "${caller}" == "refute_line" ]]; then
    : "${lines?}"
    local -ar stream_lines=("${lines[@]}")
    local -r stream_type=output
  elif [[ "${caller}" == "refute_stderr_line" ]]; then
    : "${stderr_lines?}"
    local -ar stream_lines=("${stderr_lines[@]}")
    local -r stream_type=stderr
  else
    echo "Unexpected call to \`${FUNCNAME[0]}\`
Did you mean to call \`refute_line\` or \`refute_stderr_line\`?" |
      batslib_decorate "ERROR: ${FUNCNAME[0]}" |
      fail
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

  local -r unexpected="$1"

  if (( is_mode_regexp == 1 )); then
    __check_is_valid_regex "$unexpected" "$caller" || return $?
  fi

  if (( is_match_line )); then
    if (( is_mode_regexp )); then
      if [[ ${stream_lines[$idx]} =~ $unexpected ]]; then
        batslib_print_kv_single 6 \
        'index' "$idx" \
        'regexp' "$unexpected" \
        'line'  "${stream_lines[$idx]}" \
        | batslib_decorate 'regular expression should not match line' \
        | fail
      fi
    elif (( is_mode_partial )); then
      if [[ ${stream_lines[$idx]} == *"$unexpected"* ]]; then
        batslib_print_kv_single 9 \
        'index'     "$idx" \
        'substring' "$unexpected" \
        'line'      "${stream_lines[$idx]}" \
        | batslib_decorate 'line should not contain substring' \
        | fail
      fi
    else
      if [[ ${stream_lines[$idx]} == "$unexpected" ]]; then
        batslib_print_kv_single 5 \
        'index' "$idx" \
        'line'  "${stream_lines[$idx]}" \
        | batslib_decorate 'line should differ' \
        | fail
      fi
    fi
  else
    if (( is_mode_regexp )); then
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        if [[ ${stream_lines[$idx]} =~ $unexpected ]]; then
          { local -ar single=( 'regexp' "$unexpected" 'index' "$idx" )
            local -a may_be_multi=( "${stream_type}" "${!stream_type}" )
            local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" | batslib_prefix | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } \
          | batslib_decorate 'no line should match the regular expression' \
          | fail
          return $?
        fi
      done
    elif (( is_mode_partial )); then
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        if [[ ${stream_lines[$idx]} == *"$unexpected"* ]]; then
          { local -ar single=( 'substring' "$unexpected" 'index' "$idx" )
            local -a may_be_multi=( "${stream_type}" "${!stream_type}" )
            local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" | batslib_prefix | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } \
          | batslib_decorate 'no line should contain substring' \
          | fail
          return $?
        fi
      done
    else
      local -i idx
      for (( idx = 0; idx < ${#stream_lines[@]}; ++idx )); do
        if [[ ${stream_lines[$idx]} == "$unexpected" ]]; then
          { local -ar single=( 'line' "$unexpected" 'index' "$idx" )
            local -a may_be_multi=( "${stream_type}" "${!stream_type}" )
            local -ir width="$( batslib_get_max_single_line_key_width "${single[@]}" "${may_be_multi[@]}" )"
            batslib_print_kv_single "$width" "${single[@]}"
            if batslib_is_single_line "${may_be_multi[1]}"; then
              batslib_print_kv_single "$width" "${may_be_multi[@]}"
            else
              may_be_multi[1]="$( printf '%s' "${may_be_multi[1]}" | batslib_prefix | batslib_mark '>' "$idx" )"
              batslib_print_kv_multi "${may_be_multi[@]}"
            fi
          } \
          | batslib_decorate "line should not be in ${stream_type}" \
          | fail
          return $?
        fi
      done
    fi
  fi
}
