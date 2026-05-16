return {
  "ellisonleao/glow.nvim",
  cmd = "Glow",
  opts = {
    -- glow_path = "",       -- Path to glow binary (auto-detected if in $PATH)
    -- install_path = "~/.local/bin", -- Default path for installing glow binary
    border = "shadow",    -- Floating window border style
    style = "dark",      -- "dark" or "light" (overrides editor background)
    pager = false,        -- Use a pager for output
    -- width = 80,
    -- height = 100,
    width_ratio = 0.7,    -- Max width relative to nvim window
    height_ratio = 0.7,   -- Max height relative to nvim window
  },
}
