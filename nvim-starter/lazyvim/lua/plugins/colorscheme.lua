local ok, theme = pcall(require, "_local_theme")

return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = ok and theme.colorscheme or "tokyonight",
    },
  },
}
