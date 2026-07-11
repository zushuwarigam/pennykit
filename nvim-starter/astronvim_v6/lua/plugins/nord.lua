local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("nord") then return {} end

local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "nord" then return {} end
return {
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
  },
}
