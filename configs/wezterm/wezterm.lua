local wezterm = require("wezterm")
local config = {
	hide_tab_bar_if_only_one_tab = true,
	window_decorations = "NONE",
}

local ok, local_theme = pcall(dofile, wezterm.config_dir .. "/_local_theme.lua")
config.color_scheme = ok and local_theme.linux or "GruvboxDark"

return config
