local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("zenmod") then return {} end

---@type LazySpec
return {
  {
    "folke/zen-mode.nvim",
    opts = {
      window = {
        backdrop = 0.95,
        width = 120,
        height = 1,
        options = {},
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          -- you may turn on/off statusline in zen mode by setting 'laststatus'
          -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0, -- turn off the statusline in zen mode
        },
        gitsigns = { enabled = false },
        tmux = { enabled = false }, -- disables the tmux statusline
        todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
        wezterm = {
          enabled = false,
          -- can be either an absolute font size or the number of incremental steps
          font = "+4", -- (10% increase per step)
        },
      },
    },
  },
}
