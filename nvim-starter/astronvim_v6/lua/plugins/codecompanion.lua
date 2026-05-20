return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    interactions = {
      chat = { adapter = "copilot" },
      inline = { adapter = "copilot" },
    },
  },
}
