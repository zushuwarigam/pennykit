local ok, pk = pcall(require, "pennykit")


return {
  "nvim-neotest/neotest",
    enabled = ok and pk.is_enabled("neotest"),
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-go",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
          runner = "pytest",
        }),
        require("neotest-go"),
      },
    })
  end,
}
