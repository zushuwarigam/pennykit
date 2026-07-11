local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("fidget") then return {} end

return {
  "j-hui/fidget.nvim",
  opts = {
    -- options
  },
}
