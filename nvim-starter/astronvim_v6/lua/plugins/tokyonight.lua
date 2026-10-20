local ok, pk = pcall(require, "pennykit")


local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "tokyonight-night" then return {} end
return {
  {
    "folke/tokyonight.nvim",
    enabled = ok and pk.is_enabled("tokyonight"),
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
