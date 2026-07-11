local ok, pk = pcall(require, "pennykit")


return {
  "ryanmsnyder/toggleterm-manager.nvim",
    enabled = ok and pk.is_enabled("toggleterm-manager"),
  dependencies = {
    "akinsho/nvim-toggleterm.lua",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- only needed because it's a dependency of telescope
  },
  config = true,
}
