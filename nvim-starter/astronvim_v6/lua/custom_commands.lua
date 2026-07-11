vim.api.nvim_create_user_command('PKhello', function()
  print("Hello!")
end, {})

-- PennyKit Plugin Manager Commands
local plugin_manager = require "pennykit.plugin_manager"

vim.api.nvim_create_user_command('PKPluginList', function()
  plugin_manager.list_plugins()
end, { desc = "List all plugins with status" })

vim.api.nvim_create_user_command('PKPluginAdd', function()
  plugin_manager.add_plugin()
end, { desc = "Add a new user plugin" })

vim.api.nvim_create_user_command('PKPluginEnable', function()
  plugin_manager.enable_plugin()
end, { desc = "Enable a disabled plugin" })

vim.api.nvim_create_user_command('PKPluginDisable', function()
  plugin_manager.disable_plugin()
end, { desc = "Disable an enabled plugin" })

vim.api.nvim_create_user_command('PKPluginToggle', function()
  plugin_manager.toggle_plugin()
end, { desc = "Toggle plugin enabled/disabled" })

vim.api.nvim_create_user_command('PKPluginDescribe', function()
  plugin_manager.edit_plugin_description()
end, { desc = "Edit plugin description" })

vim.api.nvim_create_user_command('PKPluginSync', function()
  plugin_manager.sync_plugins()
end, { desc = "Sync registry with lua/plugins/ directory" })
