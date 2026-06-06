assert_regex() {
  local -r value="${1}"
  local -r pattern="${2}"

  if ! __check_is_valid_regex "$pattern" assert_regex; then
    return 1
  elif ! [[ "${value}" =~ ${pattern} ]]; then
    if shopt -p nocasematch &>/dev/null; then
      local case_sensitive=insensitive
    else
      local case_sensitive=sensitive
    fi
    batslib_print_kv_single_or_multi 8 \
      'value' "${value}" \
      'pattern'  "${pattern}" \
      'case' "${case_sensitive}" \
    | batslib_decorate 'value does not match regular expression' \
    | fail
  fi
}
