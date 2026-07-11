local ok, pk = pcall(require, "pennykit")


local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "catppuccin" then return {} end
return {
  {
    "catppuccin/nvim",
    enabled = ok and pk.is_enabled("catppuccin"),
    name = "catppuccin",
    opts = {
      dim_inactive = { enabled = true, percentage = 0.25 },
      highlight_overrides = {
        mocha = function(c)
          return {
            Normal = { bg = c.mantle },
            Comment = { fg = "#7687a0" },
            ["@tag.attribute"] = { style = {} },
          }
        end,
      },
    },
  },
}
