vim.api.nvim_create_user_command('PKhello', function()
  print("Hello!")
end, {})
