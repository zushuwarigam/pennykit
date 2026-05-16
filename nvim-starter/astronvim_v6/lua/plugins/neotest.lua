return {
  "nvim-neotest/neotest",
  dependencies = {
    -- "nvim-neotest/neotest-python",
    -- "nvim-neotest/neotest-go",
    -- "nvim-lua/plenary.nvim",
    -- "nvim-treesitter/nvim-treesitter",
    -- "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
  },
  -- cmd = { "Neotest" },
  -- opts = {
  --   adapters = {
  --     require("neotest-python"),
  --     require("neotest-go"),
  --   },
  -- },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({  -- ← line ~13, fails if dep missing
          dap = { justMyCode = false },
          runner = "pytest",
        }),
      },
    })
  end,
}
