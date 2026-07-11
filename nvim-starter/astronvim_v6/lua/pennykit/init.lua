-- PennyKit Module
-- Interactive plugin management for AstroNvim

local M = {}

-- Path to registry file
local registry_path = vim.fn.stdpath "config" .. "/lua/pennykit/plugin_registry.json"

-- Cache for registry
local _registry = nil

--- Load registry from disk
---@param force? boolean Force reload from disk
---@return table
function M.load_registry(force)
  -- Return cached version if available and not forcing reload
  if _registry and not force then return _registry end
  
  local file = io.open(registry_path, "r")
  if not file then
    _registry = { plugins = {} }
    return _registry
  end
  local content = file:read "*a"
  file:close()
  local ok, data = pcall(vim.json.decode, content)
  if ok and data and data.plugins then
    _registry = data
  else
    _registry = { plugins = {} }
  end
  return _registry
end

--- Save registry to disk
---@param registry table
function M.save_registry(registry)
  -- Ensure directory exists
  local dir = vim.fn.fnamemodify(registry_path, ":h")
  vim.fn.mkdir(dir, "p")
  local file = io.open(registry_path, "w")
  if not file then
    vim.notify("Failed to save plugin registry", vim.log.levels.ERROR)
    return
  end
  file:write(vim.json.encode(registry))
  file:close()
  _registry = registry
end

--- Check if a plugin is enabled
--- Returns true if:
--- 1. Plugin is in registry and enabled = true
--- 2. Plugin is NOT in registry (default behavior: enabled)
---@param plugin_name string
---@return boolean
function M.is_enabled(plugin_name)
  -- Always load fresh from disk to get current state
  local registry = M.load_registry(true)
  -- If plugin not in registry, default to enabled
  if not registry.plugins[plugin_name] then return true end
  return registry.plugins[plugin_name].enabled == true
end

--- Set plugin enabled state
---@param plugin_name string
---@param enabled boolean
function M.set_enabled(plugin_name, enabled)
  -- Always load fresh from disk to avoid stale cache
  local registry = M.load_registry(true)
  if not registry.plugins[plugin_name] then
    registry.plugins[plugin_name] = {
      enabled = enabled,
      description = "",
      source = "user",
    }
  else
    registry.plugins[plugin_name].enabled = enabled
  end
  M.save_registry(registry)
end

return M
