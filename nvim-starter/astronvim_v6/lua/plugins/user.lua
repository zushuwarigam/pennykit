-- User Plugin Overrides
-- Add your custom plugin configurations here
-- Each plugin should be in its own file for easier management

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("user") then return { enabled = false } end

---@type LazySpec
return {
  -- Disable better-escape.nvim (example)
  { "max397574/better-escape.nvim", enabled = false },
}
