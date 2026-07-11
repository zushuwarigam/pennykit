local ok, pk = pcall(require, "pennykit")


return {
  "j-hui/fidget.nvim",
    enabled = ok and pk.is_enabled("fidget"),
  opts = {
    -- options
  },
}
