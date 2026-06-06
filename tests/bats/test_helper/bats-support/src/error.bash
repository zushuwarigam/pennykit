fail() {
  (( $# == 0 )) && batslib_err || batslib_err "$@"
  return 1
}
