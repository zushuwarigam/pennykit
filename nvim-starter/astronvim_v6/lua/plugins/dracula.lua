local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("dracula") then return { enabled = false } end

local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "dracula" then return {} end
return {
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
