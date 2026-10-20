local ok, pk = pcall(require, "pennykit")

-- LSP Signature Help

---@type LazySpec
return {
  "ray-x/lsp_signature.nvim",
    enabled = ok and pk.is_enabled("lsp_signature"),
  event = "BufRead",
  config = function() require("lsp_signature").setup() end,
}
