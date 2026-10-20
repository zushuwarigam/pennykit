-- ~/.config/nvim/lua/copy_word.lua
local M = {}

M.opts = {
  file_path = vim.fn.expand('~/copied_words.txt'),
  append    = true,
  separator = "\n",
  keymap = { lhs = "<leader>cw", mode = "n", noremap = true, silent = true, desc = "Copy word under cursor to file" },
}

function M.setup(user_opts)
  if user_opts then
    M.opts = vim.tbl_deep_extend("force", M.opts, user_opts)
  end

  vim.api.nvim_create_user_command(
    "CopyWordToFile",
    function() M.copy_word() end,
    {desc = "Copy the word under the cursor to a file"}
  )

  local km = M.opts.keymap
  if km and km.lhs then
    vim.keymap.set(km.mode, km.lhs, M.copy_word,
      { noremap = km.noremap, silent = km.silent, desc = km.desc })
  end
end

local function get_word()
  local w = vim.fn.expand("<cword>")
  return w ~= "" and w or nil
end

local function write_to_file(txt)
  local mode = M.opts.append and "a" or "w"
  local f, err = io.open(M.opts.file_path, mode)
  if not f then
    vim.api.nvim_err_writeln("[copy_word] cannot open file: " .. err)
    return
  end
  f:write(txt .. M.opts.separator)
  f:close()
  vim.api.nvim_echo({{("[copy_word] → %s"):format(txt), "None"}}, false, {})
end

function M.copy_word()
  local w = get_word()
  if not w then
    vim.api.nvim_err_writeln("[copy_word] no word under cursor")
    return
  end
  write_to_file(w)
end

return M
