local ok, pk = pcall(require, "pennykit")


return {
  "MeanderingProgrammer/render-markdown.nvim",
    enabled = ok and pk.is_enabled("glow"),
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  opts = {},
  ft = { "markdown" },
}
