-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 80
config.initial_rows = 25

-- or, changing the font size and color scheme.
config.font = wezterm.font("MesloLGS NF")
config.font_size = 16
config.color_scheme = "Catppuccin Mocha"

config.default_cursor_style = "BlinkingBar"

config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"

-- Finally, return the configuration to wezterm:
return config
