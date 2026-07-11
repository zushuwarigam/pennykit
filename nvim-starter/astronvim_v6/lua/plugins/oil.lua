local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("oil") then return { enabled = false } end

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    default_file_explorer = true,
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
}
