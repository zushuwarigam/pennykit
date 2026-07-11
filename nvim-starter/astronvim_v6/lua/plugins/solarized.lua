local ok, pk = pcall(require, "pennykit")


local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "solarized" then return {} end
return {
  {
    "shaunsingh/solarized.nvim",
    enabled = ok and pk.is_enabled("solarized"),
    lazy = false,
    priority = 1000,
  },
}
