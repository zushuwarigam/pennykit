return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local ok, cc_config = pcall(require,"codecompanion_config")
    print("Add codecompanion config")
    require("codecompanion").setup(ok and cc_config or {})
  end,
}
