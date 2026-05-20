local wezterm = require("wezterm")
local config = {
	hide_tab_bar_if_only_one_tab = true,
	window_decorations = "NONE",
  initial_cols = 120,
  initial_rows = 28,
  font_size = 12
}

local ok, local_theme = pcall(dofile, wezterm.home_dir .. "/.pennykit/configs/wezterm/_local_theme.lua")
config.color_scheme = ok and local_theme.linux or "GruvboxDark"

return config
