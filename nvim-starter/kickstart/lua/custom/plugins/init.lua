-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'folke/zen-mode.nvim',
    opts = {
      plugins = {
        options = {
          enabled = true,
        },
        wezterm = {
          enabled = true,
          font = '+4', -- font size increment
        },
      },
    },
    cmd = { 'ZenMode' },
  },
  {
    'nativerv/cyrillic.nvim',
    event = { 'VeryLazy' },
    config = function()
      require('cyrillic').setup {
        no_cyrillic_abbrev = false, -- default
      }
    end,
  },
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = true,
    opts = {},
  },
}
