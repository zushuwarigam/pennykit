local ok, pk = pcall(require, "pennykit")


local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "nord" then return {} end
return {
  {
    "shaunsingh/nord.nvim",
    enabled = ok and pk.is_enabled("nord"),
    lazy = false,
    priority = 1000,
  },
}
