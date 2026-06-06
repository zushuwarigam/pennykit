batslib_is_caller() {
  local -i is_mode_direct=1
  while (( $# > 0 )); do
    case "$1" in
      -i|--indirect) is_mode_direct=0; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  local -r func="$1"
  if (( is_mode_direct )); then
    [[ $func == "${FUNCNAME[2]}" ]] && return 0
  else
    local -i depth
    for (( depth=2; depth<${#FUNCNAME[@]}; ++depth )); do
      [[ $func == "${FUNCNAME[$depth]}" ]] && return 0
    done
  fi
  return 1
}
