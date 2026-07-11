-- PennyKit Plugin Manager with Telescope integration
-- Interactive plugin management for AstroNvim
-- Commands: :PKPluginSync, :PKPlugins (Telescope picker)

local M = {}
local pk = require "pennykit"

--- Core AstroNvim plugins to exclude from user management
--- These are managed by AstroNvim itself, not by PennyKit
--- NOTE: File names (without .lua) must be listed here to exclude from picker
local CORE_PLUGINS = {
  -- AstroNvim core (file names)
  ["astrocore"] = true,
  ["astrocore_rooter"] = true,
  ["astrolsp"] = true,
  ["astroui"] = true,
  ["treesitter"] = true,
  ["mason"] = true,
  -- AstroNvim plugin IDs (for reference)
  ["AstroNvim/astrocore"] = true,
  ["AstroNvim/astrolsp"] = true,
  ["AstroNvim/astroui"] = true,
  ["AstroNvim/astrotheme"] = true,
  ["AstroNvim/neo-tree.nvim"] = true,
  ["AstroNvim/telescope.nvim"] = true,
  ["AstroNvim/which-key.nvim"] = true,
  ["AstroNvim/mason.nvim"] = true,
  ["AstroNvim/mason-lspconfig.nvim"] = true,
  ["AstroNvim/mason-null-ls.nvim"] = true,
  ["AstroNvim/mason-nvim-dap.nvim"] = true,
  -- Common core dependencies
  ["nvim-lua/plenary.nvim"] = true,
  ["nvim-tree/nvim-web-devicons"] = true,
  ["MunifTanjim/nui.nvim"] = true,
  ["nvim-telescope/telescope.nvim"] = true,
  ["echasnovski/mini.icons"] = true,
  ["folke/which-key.nvim"] = true,
  ["folke/lazy.nvim"] = true,
  ["folke/trouble.nvim"] = true,
  ["folke/todo-comments.nvim"] = true,
  ["lewis6991/gitsigns.nvim"] = true,
  ["nvim-treesitter/nvim-treesitter"] = true,
  ["hrsh7th/nvim-cmp"] = true,
  ["hrsh7th/cmp-nvim-lsp"] = true,
  ["hrsh7th/cmp-buffer"] = true,
  ["hrsh7th/cmp-path"] = true,
  ["saadparwaiz1/cmp_luasnip"] = true,
  ["numToStr/Comment.nvim"] = true,
  ["echasnovski/mini.pairs"] = true,
  ["lukas-reineke/indent-blankline.nvim"] = true,
  ["akinsho/bufferline.nvim"] = true,
  ["famiu/bufdelete.nvim"] = true,
  ["goolord/alpha-nvim"] = true,
  ["renerocksai/telekasten.nvim"] = true,
  ["folke/persistence.nvim"] = true,
  ["Wansmer/treesj"] = true,
  ["axieax/urlview.nvim"] = true,
  ["chrisgrieser/nvim-early-retirement"] = true,
  ["max397574/better-escape.nvim"] = true,
  ["akinsho/toggleterm.nvim"] = true,
  ["tiagovla/scope.nvim"] = true,
  ["wthollingsworth/cmp-nvim-tags"] = true,
  -- PennyKit managed (these are config files, not separate plugins)
  ["L3MON4D3/LuaSnip"] = true, -- configured in luasnip.lua
  ["windwp/nvim-autopairs"] = true, -- configured in autopairs.lua
  ["ray-x/lsp_signature.nvim"] = true, -- configured in lsp_signature.lua
  ["folke/snacks.nvim"] = true, -- configured in snacks.lua
  ["andweeb/presence.nvim"] = true, -- configured in presence.lua
}

--- Check if a plugin is a core AstroNvim plugin
---@param plugin_name string
---@return boolean
function M.is_core_plugin(plugin_name)
  -- Check exact match in CORE_PLUGINS table
  if CORE_PLUGINS[plugin_name] then return true end

  -- Check if it's an AstroNvim plugin (by prefix)
  if plugin_name:match("^AstroNvim/") then return true end

  -- NOTE: We do NOT use substring matching here
  -- Each plugin file (like luasnip.lua, autopairs.lua) should be manageable
  -- Only plugins explicitly in CORE_PLUGINS or with AstroNvim/ prefix are core

  return false
end

--- Get plugin name from filename
---@param filename string
---@return string
function M.filename_to_name(filename)
  local name = filename:gsub("%.lua$", "")
  return name
end

--- Sync registry with lua/plugins/ directory
--- Scans all .lua files and adds missing ones to registry
function M.sync_plugins()
  -- Always load fresh from disk
  local registry = pk.load_registry(true)
  local plugins_dir = vim.fn.stdpath "config" .. "/lua/plugins"
  local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)

  local added = 0
  local skipped = 0
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    -- Skip pennykit internal files and core plugins
    if name ~= "init" and not M.is_core_plugin(name) then
      -- Don't overwrite existing entries
      if not registry.plugins[name] then
        registry.plugins[name] = {
          enabled = true,
          description = "",
          source = "static",
        }
        added = added + 1
      end
    else
      skipped = skipped + 1
    end
  end

  pk.save_registry(registry)
  return { added = added, total = #files - skipped, skipped = skipped }
end

--- Get all manageable plugins (non-core) from registry
---@return table[]
function M.get_manageable_plugins()
  -- Always load fresh from disk
  local registry = pk.load_registry(true)
  local plugins = {}

  for name, entry in pairs(registry.plugins) do
    if not M.is_core_plugin(name) then
      table.insert(plugins, {
        name = name,
        enabled = entry.enabled,
        description = entry.description or "",
        source = entry.source or "static",
        entry = entry,
      })
    end
  end

  table.sort(plugins, function(a, b) return a.name < b.name end)
  return plugins
end

--- Custom floating window picker for plugin management
function M.picker()
  -- Auto-sync first
  local stats = M.sync_plugins()

  -- Get manageable plugins
  local plugins = M.get_manageable_plugins()

  if #plugins == 0 then
    vim.notify("No plugins found to manage", vim.log.levels.INFO)
    return
  end

  -- Sort: enabled first, then alphabetically
  table.sort(plugins, function(a, b)
    if a.enabled ~= b.enabled then return a.enabled end
    return a.name < b.name
  end)

  -- Track state
  local plugin_state = {}
  for _, p in ipairs(plugins) do
    plugin_state[p.name] = p.enabled
  end

  -- Track pending changes
  local changes = {}
  local cursor_line = 1

  -- Calculate layout
  local max_name = 0
  for _, p in ipairs(plugins) do
    max_name = math.max(max_name, #p.name)
  end
  local win_width = math.min(80, math.max(50, max_name + 30))
  local win_height = math.min(#plugins + 6, vim.o.lines - 4)
  local win_width_actual = math.min(win_width, vim.o.columns - 4)
  local row = math.floor((vim.o.lines - win_height) / 2)
  local col = math.floor((vim.o.columns - win_width_actual) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width_actual,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" PennyKit Plugins (%d) ", #plugins),
    title_pos = "center",
  })

  -- Build display lines
  local function build_lines()
    local lines = {}
    -- Header
    table.insert(lines, string.format(" %d plugins synced, %d new", #plugins, stats.added))
    table.insert(lines, string.rep("─", win_width_actual - 2))
    table.insert(lines, "")
    -- Plugins
    for i, p in ipairs(plugins) do
      local enabled = plugin_state[p.name]
      local status = enabled and "✓" or "✗"
      local line = string.format("  [%s] %-" .. max_name .. "s", status, p.name)
      if p.description ~= "" then
        line = line .. "  " .. p.description
      end
      table.insert(lines, line)
    end
    -- Footer
    table.insert(lines, "")
    table.insert(lines, string.rep("─", win_width_actual - 2))
    table.insert(lines, " Tab:toggle  E:all on  D:all off  CR:apply+sync  q:quit")
    return lines
  end

  -- Render
  local function render()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, build_lines())
    vim.bo[buf].modifiable = false
    -- Set cursor to plugin line (header is 3 lines)
    pcall(vim.api.nvim_win_set_cursor, win, { cursor_line + 3, 0 })
  end

  -- Apply changes
  local function apply_changes()
    local applied = 0
    for name, enabled in pairs(changes) do
      pk.set_enabled(name, enabled)
      applied = applied + 1
    end
    if applied > 0 then
      vim.notify(string.format("Applied %d plugin changes", applied), vim.log.levels.INFO)
    end
  end

  -- Toggle plugin at cursor
  local function toggle()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    local plugin_idx = lnum - 3 -- offset for header
    if plugin_idx < 1 or plugin_idx > #plugins then return end
    local plugin = plugins[plugin_idx]
    local new_state = not plugin_state[plugin.name]
    plugin_state[plugin.name] = new_state
    changes[plugin.name] = new_state
    cursor_line = lnum
    render()
    local status = new_state and "enabled" or "disabled"
    vim.notify(string.format("%s: %s", plugin.name, status), vim.log.levels.INFO)
  end

  -- Enable all
  local function enable_all()
    for _, p in ipairs(plugins) do
      if not plugin_state[p.name] then
        plugin_state[p.name] = true
        changes[p.name] = true
      end
    end
    render()
    vim.notify("All plugins enabled", vim.log.levels.INFO)
  end

  -- Disable all
  local function disable_all()
    for _, p in ipairs(plugins) do
      if plugin_state[p.name] then
        plugin_state[p.name] = false
        changes[p.name] = false
      end
    end
    render()
    vim.notify("All plugins disabled", vim.log.levels.INFO)
  end

  -- Close picker
  local function close()
    vim.api.nvim_win_close(win, true)
  end

  -- Close and apply
  local function close_and_apply()
    apply_changes()
    close()
    vim.notify("Running :Lazy sync...", vim.log.levels.INFO)
    vim.cmd("Lazy sync")
  end

  -- Close without sync
  local function close_and_quit()
    apply_changes()
    close()
  end

  -- Show help
  local function show_help()
    local help_text = {
      "",
      "  PennyKit Plugin Manager - Help",
      "",
      "  Navigation:
      "    j/k       Move up/down",
      "    <Tab>     Toggle current plugin",
      "",
      "  Actions:
      "    E         Enable all plugins",
      "    D         Disable all plugins",
      "    <CR>      Apply changes & run :Lazy sync",
      "    q         Apply changes & close",
      "",
      "  Plugins marked [✓] are enabled",
      "  Plugins marked [✗] are disabled",
      "",
    }
    local help_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_text)
    vim.bo[help_buf].modifiable = false
    vim.api.nvim_open_win(help_buf, true, {
      relative = "editor",
      width = 45,
      height = #help_text,
      row = 5,
      col = 5,
      style = "minimal",
      border = "rounded",
      title = " Help ",
      title_pos = "center",
    })
    vim.keymap.set("n", "q", function() vim.cmd("close") end, { buffer = help_buf })
    vim.keymap.set("n", "<Esc>", function() vim.cmd("close") end, { buffer = help_buf })
  end

  -- Set keymaps
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<Tab>", toggle, opts)
  vim.keymap.set("n", "j", function()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    if lnum < #plugins + 2 then -- +2 for header, +1 for last line
      cursor_line = lnum + 1
      vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })
    end
  end, opts)
  vim.keymap.set("n", "k", function()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    if lnum > 4 then -- header is 3 lines
      cursor_line = lnum - 1
      vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })
    end
  end, opts)
  vim.keymap.set("n", "E", enable_all, opts)
  vim.keymap.set("n", "D", disable_all, opts)
  vim.keymap.set("n", "<CR>", close_and_apply, opts)
  vim.keymap.set("n", "q", close_and_quit, opts)
  vim.keymap.set("n", "<Esc>", close_and_quit, opts)
  vim.keymap.set("n", "h", show_help, opts)

  -- Initial render
  render()
end

--- Add plugin (user plugins only)
function M.add_plugin()
  vim.ui.input({ prompt = "Plugin URL or shorthand (e.g., user/repo): " }, function(input)
    if not input or input == "" then
      vim.notify("Cancelled", vim.log.levels.INFO)
      return
    end

    -- Parse URL to get plugin name
    local name = input:gsub("^https?://github%.com/", ""):gsub("%.git$", ""):gsub("/$", "")

    -- Check if it's a core plugin
    if M.is_core_plugin(name) then
      vim.notify("Cannot add core AstroNvim plugin: " .. name, vim.log.levels.WARN)
      return
    end

    local registry = pk.load_registry()

    -- Check if already exists
    if registry.plugins[name] then
      vim.notify("Plugin " .. name .. " already exists (use :PKPlugins to enable/disable)", vim.log.levels.WARN)
      return
    end

    -- Add to registry
    registry.plugins[name] = {
      enabled = true,
      description = "",
      source = "user",
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

--- Show status of all plugins (interactive multi-column window)
function M.show_status()
  -- Always load fresh from disk
  local registry = pk.load_registry(true)
  local plugins_dir = vim.fn.stdpath "config" .. "/lua/plugins"
  local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)

  -- Collect all plugins with details
  local all_plugins = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    if name ~= "init" and not M.is_core_plugin(name) then
      local entry = registry.plugins[name]
      local enabled, description
      if entry then
        enabled = entry.enabled
        description = entry.description or ""
      else
        enabled = true
        description = ""
      end
      table.insert(all_plugins, { name = name, enabled = enabled, description = description })
    end
  end

  -- Sort: enabled first, then alphabetically
  table.sort(all_plugins, function(a, b)
    if a.enabled ~= b.enabled then return a.enabled end
    return a.name < b.name
  end)

  -- Count stats
  local enabled_count = 0
  local disabled_count = 0
  for _, p in ipairs(all_plugins) do
    if p.enabled then
      enabled_count = enabled_count + 1
    else
      disabled_count = disabled_count + 1
    end
  end

  -- Find max name length for alignment
  local max_name = 0
  for _, p in ipairs(all_plugins) do
    if #p.name > max_name then max_name = #p.name end
  end
  max_name = math.min(max_name, 22)

  -- Column width: icon + space + name + padding
  local col_width = 4 + max_name

  -- Determine number of columns based on plugin count and screen width
  local num_cols = 1
  if #all_plugins > 12 then
    local max_cols = math.floor((vim.o.columns - 4) / (col_width + 2))
    num_cols = math.min(max_cols, math.ceil(#all_plugins / 12))
    num_cols = math.max(num_cols, 1)
  end

  -- Arrange plugins into columns (fill by rows first for better readability)
  local rows_per_col = math.ceil(#all_plugins / num_cols)
  local columns = {}
  for c = 1, num_cols do
    columns[c] = {}
  end
  for i, p in ipairs(all_plugins) do
    local col = math.ceil(i / rows_per_col)
    local row = ((i - 1) % rows_per_col) + 1
    columns[col][row] = p
  end

  -- Build display lines
  local lines = {}
  local total_width = col_width * num_cols + (num_cols - 1) * 2

  -- Header
  table.insert(lines, "")
  table.insert(lines, "  PennyKit Plugins")
  table.insert(lines, "  " .. string.rep("═", total_width))
  table.insert(lines, "")

  -- Build multi-column lines
  for row = 1, rows_per_col do
    local line_parts = {}
    for col = 1, num_cols do
      local p = columns[col][row]
      if p then
        local icon = p.enabled and "✓" or "✗"
        local cell = string.format("%s %-" .. max_name .. "s", icon, p.name)
        table.insert(line_parts, cell)
      else
        table.insert(line_parts, string.rep(" ", max_name + 2))
      end
    end
    table.insert(lines, "  " .. table.concat(line_parts, "  "))
  end

  -- Footer
  table.insert(lines, "")
  table.insert(lines, "  " .. string.rep("─", total_width))
  table.insert(lines, string.format("  %d enabled  │  %d disabled  │  %d total", enabled_count, disabled_count, #all_plugins))
  table.insert(lines, "")
  table.insert(lines, "  <CR> toggle  │  R refresh  │  P picker  │  q close")
  table.insert(lines, "")

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "pennykit-status"

  -- Calculate width based on columns
  local width = total_width + 4
  width = math.max(width, 50)
  width = math.min(width, vim.o.columns - 4)

  local height = #lines
  local row_pos = math.floor((vim.o.lines - height) / 2)
  local col_pos = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row_pos,
    col = col_pos,
    style = "minimal",
    border = "rounded",
    title = " Plugin Status ",
    title_pos = "center",
  })

  -- Get plugin name from cursor position (handles multi-column)
  local function get_plugin_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(win)[1]
    local line_text = lines[cursor] or ""

    -- Single column: simple match
    if num_cols == 1 then
      return line_text:match("^  [✓✗] (%S+)")
    end

    -- Multi-column: calculate which column based on cursor byte position
    local cursor_col = vim.api.nvim_win_get_cursor(win)[2]
    local cell_start = 2 -- after "  "

    for c = 1, num_cols do
      local cell_end = cell_start + col_width
      if cursor_col >= cell_start and cursor_col < cell_end then
        -- Extract name from this cell
        local cell_text = line_text:sub(cell_start + 1, cell_end)
        local name = cell_text:match("[✓✗] (%S+)")
        return name
      end
      cell_start = cell_end + 2 -- +2 for "  " separator
    end
    return nil
  end

  -- Keymaps
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local name = get_plugin_at_cursor()
    if name then
      local current = pk.is_enabled(name)
      pk.set_enabled(name, not current)
      M.show_status() -- Refresh
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "R", function() M.show_status() end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "P", function()
    vim.api.nvim_win_close(win, true)
    M.picker()
  end, { buffer = buf, nowait = true })
end

--- Show help for plugin management
function M.show_help()
  local help_lines = {
    "",
    "  PennyKit Plugin Manager - Help",
    "  ═══════════════════════════════════════════════════",
    "",
    "  How plugins work:",
    "  ────────────────────────────────────────────────────",
    "  1. Each plugin has its own file in lua/plugins/",
    "  2. Each file has a guard clause that checks registry:",
    "     enabled = ok and pk.is_enabled(\"name\")",
    "  3. Registry stores enabled/disabled state",
    "  4. Default: plugins NOT in registry are ENABLED",
    "",
    "  Commands:",
    "  ────────────────────────────────────────────────────",
    "  :PKPlugins      Open Telescope picker (auto-syncs)",
    "  :PKPluginAdd    Add a new plugin",
    "  :PKPluginSync   Sync registry with lua/plugins/",
    "  :PKPluginStatus Show enabled/disabled status",
    "  :PKPluginHelp   Show this help",
    "",
    "  Telescope keymaps (in :PKPlugins):",
    "  ────────────────────────────────────────────────────",
    "  <Tab>          Toggle current plugin",
    "  <C-e>          Enable all plugins",
    "  <C-d>          Disable all plugins",
    "  <C-h>          Show this help",
    "  <CR>           Close & run :Lazy sync",
    "  <Esc>          Close picker",
    "",
    "  Registry location:",
    "  ────────────────────────────────────────────────────",
    "  lua/pennykit/plugin_registry.json",
    "",
    "  Example workflow:",
    "  ────────────────────────────────────────────────────",
    "  1. Open picker: <Leader>pp",
    "  2. Find plugin: type name to filter",
    "  3. Toggle: press <Tab>",
    "  4. Close: press <CR> (auto-syncs)",
    "",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local width = 55
  local height = #help_lines
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
    title = " Help ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
end

return M
