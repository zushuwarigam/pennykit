return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-go",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
  },
  cmd = { "Neotest" },
  opts = {
    adapters = {
      require("neotest-python"),
      require("neotest-go"),
    },
  },
}
