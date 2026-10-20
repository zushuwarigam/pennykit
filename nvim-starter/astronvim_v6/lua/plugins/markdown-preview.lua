local ok, pk = pcall(require, "pennykit")


return {
  "iamcco/markdown-preview.nvim",
    enabled = ok and pk.is_enabled("markdown-preview"),
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = "markdown",
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  init = function()
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
  end,
}
