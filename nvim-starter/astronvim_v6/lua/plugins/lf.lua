return {
  "lmburns/lf.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "akinsho/toggleterm.nvim" },
  config = function()
    require("lf").setup({
      -- escape_quit = false,       -- don't quit lf on <Esc>
      border = "rounded",
      -- height = 0.80,
      -- width = 0.85,
      -- mappings = true,           -- default <leader>lf keybind
    })
    vim.keymap.set("n", "<leader>tF", "<Cmd>Lf<CR>", { desc = "Open lf file manager" })
  end,
}
