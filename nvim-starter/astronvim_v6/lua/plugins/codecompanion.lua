local ok, pk = pcall(require, "pennykit")


return {
  "olimorris/codecompanion.nvim",
    enabled = ok and pk.is_enabled("codecompanion"),
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local ok, cc_config = pcall(require,"codecompanion_config")
    require("codecompanion").setup((ok and cc_config) or {})
  end,
}
