local ok, pk = pcall(require, "pennykit")

-- User Plugin Overrides
-- Add your custom plugin configurations here
-- Each plugin should be in its own file for easier management


---@type LazySpec
return {
  -- Disable better-escape.nvim (example)
  { "max397574/better-escape.nvim",
    enabled = ok and pk.is_enabled("user"), enabled = false },
}
