-- PennyKit Plugin Manager with Telescope integration
-- Interactive plugin management for AstroNvim
-- Commands: :PKPluginSync, :PKPlugins (Telescope picker)

local M = {}
local pk = require "pennykit"

--- Core AstroNvim plugins to exclude from user management
--- These are managed by AstroNvim itself, not by PennyKit
local CORE_PLUGINS = {
  -- AstroNvim core
  ["AstroNvim/astrocore"] = true,
  ["AstroNvim/astrocore_rooter"] = true,
  ["AstroNvim/astrolsp"] = true,
  ["AstroNvim/astroui"] = true,
  ["AstroNvim/astroui-colors"] = true,
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
  ["nvim-neo-tree/neo-tree.nvim"] = true,
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
  ["L3MON4D3/LuaSnip"] = true,
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
}

--- Check if a plugin is a core AstroNvim plugin
---@param plugin_name string
---@return boolean
function M.is_core_plugin(plugin_name)
  -- Check exact match
  if CORE_PLUGINS[plugin_name] then return true end

  -- Check if it's an AstroNvim plugin (by prefix)
  if plugin_name:match("^AstroNvim/") then return true end

  -- Check common core plugins by name
  local core_names = {
    "astrocore", "astrolsp", "astroui", "astrotheme",
    "neo-tree", "telescope", "which-key", "mason",
    "plenary", "nui", "nvim-web-devicons", "mini.icons",
    "treesitter", "nvim-cmp", "luasnip", "gitsigns",
    "bufferline", "toggleterm", "alpha-nvim", "scope",
  }

  for _, core_name in ipairs(core_names) do
    if plugin_name:match(core_name) then return true end
  end

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
  local registry = pk.load_registry()
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
  local registry = pk.load_registry()
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

--- Create Telescope picker for plugin management
function M.picker()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  -- Auto-sync first
  local stats = M.sync_plugins()

  -- Get manageable plugins
  local plugins = M.get_manageable_plugins()

  if #plugins == 0 then
    vim.notify("No plugins found to manage", vim.log.levels.INFO)
    return
  end

  -- Create custom picker
  pickers
    .new({}, {
      prompt_title = "PennyKit Plugins (synced: " .. stats.added .. " new)",
      finder = finders.new_table {
        results = plugins,
        entry_maker = function(entry)
          local status = entry.enabled and "✓" or "✗"
          local display = string.format("[%s] %s", status, entry.name)
          if entry.description ~= "" then display = display .. " — " .. entry.description end
          return {
            value = entry,
            display = display,
            ordinal = entry.name,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      layout_strategy = "vertical",
      layout_config = {
        vertical = {
          prompt_position = "top",
          preview_cutoff = 0,
          width = 0.8,
          height = 0.8,
        },
      },
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle selection (space)
        map("i", "<C-space>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            local plugin = selection.value
            local new_state = not plugin.enabled
            pk.set_enabled(plugin.name, new_state)

            -- Update the display
            local new_status = new_state and "✓" or "✗"
            local new_display = string.format("[%s] %s", new_status, plugin.name)
            if plugin.description ~= "" then new_display = new_display .. " — " .. plugin.description end

            selection.display = new_display
            plugin.enabled = new_state

            -- Refresh the picker
            actions.refresh(prompt_bufnr)

            local status_text = new_state and "enabled" or "disabled"
            vim.notify(plugin.name .. " " .. status_text, vim.log.levels.INFO)
          end
        end)

        -- Toggle selection (normal mode space)
        map("n", "<space>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            local plugin = selection.value
            local new_state = not plugin.enabled
            pk.set_enabled(plugin.name, new_state)

            local new_status = new_state and "✓" or "✗"
            local new_display = string.format("[%s] %s", new_status, plugin.name)
            if plugin.description ~= "" then new_display = new_display .. " — " .. plugin.description end

            selection.display = new_display
            plugin.enabled = new_state

            actions.refresh(prompt_bufnr)

            local status_text = new_state and "enabled" or "disabled"
            vim.notify(plugin.name .. " " .. status_text, vim.log.levels.INFO)
          end
        end)

        -- Enable all visible
        map("i", "<C-e>", function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local manager = picker.manager
          if manager then
            for _, entry in ipairs(manager.get_results(manager)) do
              if entry.value and not entry.value.enabled then
                pk.set_enabled(entry.value.name, true)
                entry.value.enabled = true
                local new_display = string.format("[✓] %s", entry.value.name)
                if entry.value.description ~= "" then
                  new_display = new_display .. " — " .. entry.value.description
                end
                entry.display = new_display
              end
            end
            actions.refresh(prompt_bufnr)
            vim.notify("All plugins enabled", vim.log.levels.INFO)
          end
        end)

        -- Disable all visible
        map("i", "<C-d>", function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local manager = picker.manager
          if manager then
            for _, entry in ipairs(manager.get_results(manager)) do
              if entry.value and entry.value.enabled then
                pk.set_enabled(entry.value.name, false)
                entry.value.enabled = false
                local new_display = string.format("[✗] %s", entry.value.name)
                if entry.value.description ~= "" then
                  new_display = new_display .. " — " .. entry.value.description
                end
                entry.display = new_display
              end
            end
            actions.refresh(prompt_bufnr)
            vim.notify("All plugins disabled", vim.log.levels.INFO)
          end
        end)

        -- Close and notify to restart
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            vim.notify("Changes applied. Run :Lazy sync to install/remove plugins if needed.", vim.log.levels.INFO)
          end
        end)

        return true
      end,
    })
    :find()
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

return M
