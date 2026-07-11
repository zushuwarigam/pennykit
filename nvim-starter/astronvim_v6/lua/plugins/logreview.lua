local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("logreview") then return false end

return {
  "andreshazard/vim-logreview",
  cmd = { "Logreview" },
  ft = { "log", "syslog" },
  opts = {},
}
