local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("solarized") then return false end

local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "solarized" then return {} end
return {
  {
    "shaunsingh/solarized.nvim",
    lazy = false,
    priority = 1000,
  },
}
