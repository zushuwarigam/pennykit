return {
  "rest-nvim/rest.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = "http",
  build = nil,
  config = function()
    require("rest-nvim").setup()
  end,
}
