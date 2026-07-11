local ok, pk = pcall(require, "pennykit")


local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "dracula" then return {} end
return {
  {
    "Mofiqul/dracula.nvim",
    enabled = ok and pk.is_enabled("dracula"),
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
