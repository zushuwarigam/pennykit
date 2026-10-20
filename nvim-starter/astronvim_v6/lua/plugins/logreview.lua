local ok, pk = pcall(require, "pennykit")


return {
  "andreshazard/vim-logreview",
    enabled = ok and pk.is_enabled("logreview"),
  cmd = { "Logreview" },
  ft = { "log", "syslog" },
  opts = {},
}
