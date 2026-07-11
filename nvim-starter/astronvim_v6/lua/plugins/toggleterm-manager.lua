local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("toggleterm-manager") then return { enabled = false } end

return {
  "ryanmsnyder/toggleterm-manager.nvim",
  dependencies = {
    "akinsho/nvim-toggleterm.lua",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- only needed because it's a dependency of telescope
  },
  config = true,
}
