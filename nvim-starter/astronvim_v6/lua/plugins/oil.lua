local ok, pk = pcall(require, "pennykit")


return {
  "stevearc/oil.nvim",
    enabled = ok and pk.is_enabled("oil"),
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    default_file_explorer = true,
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
}
