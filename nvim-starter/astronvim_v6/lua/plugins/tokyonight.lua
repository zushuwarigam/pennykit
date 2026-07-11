local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("tokyonight") then return false end

local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "tokyonight-night" then return {} end
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
