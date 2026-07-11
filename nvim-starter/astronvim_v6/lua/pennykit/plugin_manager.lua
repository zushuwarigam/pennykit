-- PennyKit Plugin Manager
-- Interactive plugin management for AstroNvim
-- Commands: :PKPluginAdd, :PKPluginDisable, :PKPluginToggle, :PKPluginList, :PKPluginSync

local M = {}
local pk = require "pennykit"

--- Get plugin name from filename
---@param filename string
---@return string
function M.filename_to_name(filename)
  -- Convert "__" back to "/" for display
  local name = filename:gsub("%.lua$", "")
  return name
end

--- Create a floating window with buffer content
---@param lines string[]
---@param opts? table
function M.create_float(lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "pennykit-plugin-list"

  local width = opts.width or math.min(vim.o.columns - 4, 80)
  local height = math.min(#lines, opts.height or vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title or " Plugin Manager ",
    title_pos = "center",
  })

  -- Keymaps for the float
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })

  return buf, win
end

--- Sync registry with lua/plugins/ directory
--- Scans all .lua files and adds missing ones to registry
function M.sync_plugins()
  local registry = pk.load_registry()
  local plugins_dir = vim.fn.stdpath "config" .. "/lua/plugins"
  local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)

  local added = 0
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    -- Skip pennykit internal files
    if name ~= "init" then
      -- Don't overwrite existing entries (especially external tools)
      if not registry.plugins[name] then
        registry.plugins[name] = {
          enabled = true,
          description = "",
          source = "static",
          type = "plugin",
        }
        added = added + 1
      elseif registry.plugins[name].type == "tool" then
        -- Skip external tools, don't mark as static
      elseif not registry.plugins[name].type then
        -- Add type field to existing entries
        registry.plugins[name].type = "plugin"
      end
    end
  end

  pk.save_registry(registry)
  vim.notify("Synced plugins: " .. added .. " new, " .. #files .. " total", vim.log.levels.INFO)
end

--- Show list of all plugins
function M.list_plugins()
  local registry = pk.load_registry()
  local lines = {
    "╔══════════════════════════════════════════════════════════════╗",
    "║                    PennyKit Plugin Manager                   ║",
    "╚══════════════════════════════════════════════════════════════╝",
    "",
  }

  -- Group plugins by source
  local static_plugins = {}
  local user_plugins = {}

  for name, entry in pairs(registry.plugins) do
    if entry.source == "user" then
      table.insert(user_plugins, { name = name, entry = entry })
    else
      table.insert(static_plugins, { name = name, entry = entry })
    end
  end

  -- Sort each group
  table.sort(static_plugins, function(a, b) return a.name < b.name end)
  table.sort(user_plugins, function(a, b) return a.name < b.name end)

  -- Show static plugins
  table.insert(lines, "  Static plugins (lua/plugins/):")
  table.insert(lines, "  ─────────────────────────────────────")
  if #static_plugins == 0 then
    table.insert(lines, "  (run :PKPluginSync to populate)")
  else
    for _, p in ipairs(static_plugins) do
      local status = p.entry.enabled and "✓" or "✗"
      local desc = p.entry.description ~= "" and (" — " .. p.entry.description) or ""
      table.insert(lines, string.format("  [%s] %s%s", status, p.name, desc))
    end
  end
  table.insert(lines, "")

  -- Show user plugins
  table.insert(lines, "  User plugins (added via :PKPluginAdd):")
  table.insert(lines, "  ─────────────────────────────────────")
  if #user_plugins == 0 then
    table.insert(lines, "  (none)")
  else
    for _, p in ipairs(user_plugins) do
      local status = p.entry.enabled and "✓" or "✗"
      local desc = p.entry.description ~= "" and (" — " .. p.entry.description) or ""
      table.insert(lines, string.format("  [%s] %s%s", status, p.name, desc))
    end
  end
  table.insert(lines, "")

  -- Show external tools
  local external_tools = {}
  for name, entry in pairs(registry.plugins) do
    if entry.type == "tool" then
      table.insert(external_tools, { name = name, entry = entry })
    end
  end
  table.sort(external_tools, function(a, b) return a.name < b.name end)

  table.insert(lines, "  External tools (added via :PKToolAdd):")
  table.insert(lines, "  ─────────────────────────────────────")
  if #external_tools == 0 then
    table.insert(lines, "  (none)")
  else
    for _, p in ipairs(external_tools) do
      local status = p.entry.enabled and "✓" or "✗"
      local desc = p.entry.description ~= "" and (" — " .. p.entry.description) or ""
      table.insert(lines, string.format("  [%s] %s%s", status, p.name, desc))
    end
  end
  table.insert(lines, "")
  table.insert(lines, "  Press q to close")

  M.create_float(lines, { title = " Plugin Manager - List ", height = math.min(#lines, 40) })
end

--- Interactive add plugin (user plugins only)
function M.add_plugin()
  vim.ui.input({ prompt = "Plugin URL or shorthand (e.g., user/repo): " }, function(input)
    if not input or input == "" then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    -- Parse URL to get plugin name
    local name = input:gsub("^https?://github%.com/", ""):gsub("%.git$", ""):gsub("/$", "")

    local registry = pk.load_registry()

    -- Check if already exists
    if registry.plugins[name] then
      vim.notify("Plugin " .. name .. " already exists (use :PKPluginToggle to enable/disable)", vim.log.levels.WARN)
      return
    end

    -- Add to registry
    registry.plugins[name] = {
      enabled = true,
      description = "",
      source = "user",
      type = "plugin",
    }
    pk.save_registry(registry)

    -- Generate plugin file
    local plugins_dir = vim.fn.stdpath "config" .. "/lua/plugins"
    vim.fn.mkdir(plugins_dir, "p")

    local filename = name:gsub("/", "__") .. ".lua"
    local filepath = plugins_dir .. "/" .. filename
    local content = string.format(
      '-- Managed by PennyKit Plugin Manager\n-- Source: user\n-- To customize, edit this file directly\n\n---@type LazySpec\nreturn {\n  "%s",\n}\n',
      name
    )
    local file = io.open(filepath, "w")
    if file then
      file:write(content)
      file:close()
    end

    vim.notify("Added plugin: " .. name .. "\nRun :Lazy sync to install", vim.log.levels.INFO)
  end)
end

--- Interactive disable plugin (sets enabled = false, keeps file)
function M.disable_plugin()
  local registry = pk.load_registry()
  local names = {}

  for name, entry in pairs(registry.plugins) do
    if entry.enabled then table.insert(names, name) end
  end

  if #names == 0 then
    vim.notify("No enabled plugins to disable", vim.log.levels.INFO)
    return
  end

  table.sort(names)
  vim.ui.select(names, {
    prompt = "Select plugin to disable:",
    format_item = function(item)
      local entry = registry.plugins[item]
      local desc = entry.description ~= "" and (" — " .. entry.description) or ""
      return string.format("%s%s", item, desc)
    end,
  }, function(choice)
    if not choice then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    pk.set_enabled(choice, false)
    vim.notify("Disabled: " .. choice .. "\nRun :Lazy sync to apply", vim.log.levels.INFO)
  end)
end

--- Interactive enable plugin (sets enabled = true)
function M.enable_plugin()
  local registry = pk.load_registry()
  local names = {}

  for name, entry in pairs(registry.plugins) do
    if not entry.enabled then table.insert(names, name) end
  end

  if #names == 0 then
    vim.notify("No disabled plugins to enable", vim.log.levels.INFO)
    return
  end

  table.sort(names)
  vim.ui.select(names, {
    prompt = "Select plugin to enable:",
    format_item = function(item)
      local entry = registry.plugins[item]
      local desc = entry.description ~= "" and (" — " .. entry.description) or ""
      return string.format("%s%s", item, desc)
    end,
  }, function(choice)
    if not choice then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    pk.set_enabled(choice, true)
    vim.notify("Enabled: " .. choice .. "\nRun :Lazy sync to apply", vim.log.levels.INFO)
  end)
end

--- Interactive toggle plugin enable/disable
function M.toggle_plugin()
  local registry = pk.load_registry()
  local names = vim.tbl_keys(registry.plugins)

  if #names == 0 then
    vim.notify("No plugins found. Run :PKPluginSync first.", vim.log.levels.INFO)
    return
  end

  table.sort(names)
  vim.ui.select(names, {
    prompt = "Select plugin to toggle:",
    format_item = function(item)
      local entry = registry.plugins[item]
      local status = entry.enabled and "✓" or "✗"
      local desc = entry.description ~= "" and (" — " .. entry.description) or ""
      return string.format("[%s] %s%s", status, item, desc)
    end,
  }, function(choice)
    if not choice then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    local new_state = not registry.plugins[choice].enabled
    pk.set_enabled(choice, new_state)

    local status = new_state and "enabled" or "disabled"
    vim.notify(status .. ": " .. choice .. "\nRun :Lazy sync to apply", vim.log.levels.INFO)
  end)
end

--- Add external tool (non-Neovim package)
function M.add_external_tool()
  vim.ui.input({ prompt = "Tool name or GitHub URL: " }, function(input)
    if not input or input == "" then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    -- Parse URL to get name
    local name = input:gsub("^https?://github%.com/", ""):gsub("%.git$", ""):gsub("/$", "")

    local registry = pk.load_registry()

    -- Check if already exists
    if registry.plugins[name] then
      vim.notify("Tool " .. name .. " already exists", vim.log.levels.WARN)
      return
    end

    -- Add to registry
    registry.plugins[name] = {
      enabled = true,
      description = "",
      source = "external",
      type = "tool",
    }
    pk.save_registry(registry)

    vim.notify("Added external tool: " .. name, vim.log.levels.INFO)
  end)
end

--- Edit plugin description
function M.edit_plugin_description()
  local registry = pk.load_registry()
  local names = vim.tbl_keys(registry.plugins)

  if #names == 0 then
    vim.notify("No plugins found. Run :PKPluginSync first.", vim.log.levels.INFO)
    return
  end

  table.sort(names)
  vim.ui.select(names, {
    prompt = "Select plugin to describe:",
    format_item = function(item)
      local entry = registry.plugins[item]
      local desc = entry.description ~= "" and entry.description or "(no description)"
      return string.format("%s — %s", item, desc)
    end,
  }, function(choice)
    if not choice then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    vim.ui.input({
      prompt = "Description for " .. choice .. ":",
      default = registry.plugins[choice].description or "",
    }, function(input)
      if input then
        registry.plugins[choice].description = input
        pk.save_registry(registry)
        vim.notify("Updated description for " .. choice, vim.log.levels.INFO)
      end
    end)
  end)
end

return M
