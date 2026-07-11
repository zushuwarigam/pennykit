vim.api.nvim_create_user_command('PKhello', function()
  print("Hello!")
end, {})

-- PennyKit Plugin Manager Commands
local plugin_manager = require "pennykit.plugin_manager"

vim.api.nvim_create_user_command('PKPlugins', function()
  plugin_manager.picker()
end, { desc = "PennyKit plugin manager (Telescope)" })

vim.api.nvim_create_user_command('PKPluginAdd', function()
  plugin_manager.add_plugin()
end, { desc = "Add a new user plugin" })

vim.api.nvim_create_user_command('PKPluginSync', function()
  local stats = plugin_manager.sync_plugins()
  vim.notify(
    string.format("Synced: %d new, %d total, %d skipped (core)", stats.added, stats.total, stats.skipped),
    vim.log.levels.INFO
  )
end, { desc = "Sync registry with lua/plugins/ directory" })
