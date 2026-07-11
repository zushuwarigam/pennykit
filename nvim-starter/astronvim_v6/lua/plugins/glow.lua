local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("glow") then return false end

return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  opts = {},
  ft = { "markdown" },
}
