-- LSP Signature Help
local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("lsp_signature") then return { enabled = false } end

---@type LazySpec
return {
  "ray-x/lsp_signature.nvim",
  event = "BufRead",
  config = function() require("lsp_signature").setup() end,
}
