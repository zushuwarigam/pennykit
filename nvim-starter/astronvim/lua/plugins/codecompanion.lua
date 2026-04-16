return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local cc_config = require("codecompanion_config")
    require("codecompanion").setup(cc_config)
  end,
}
