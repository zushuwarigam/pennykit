local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("lf") then return false end

return {
  "lmburns/lf.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "akinsho/toggleterm.nvim" },
  config = function()
    require("lf").setup({
      -- escape_quit = false,       -- don't quit lf on <Esc>
      border = "rounded",
      -- height = 0.80,
      -- width = 0.85,
      -- mappings = true,           -- default <leader>lf keybind
    })
    vim.keymap.set("n", "<leader>tF", "<Cmd>Lf<CR>", { desc = "Open lf file manager" })

    -- Press t in lf to open a terminal in the current directory (and close lf)
    vim.api.nvim_create_autocmd("WinClosed", {
      group = vim.api.nvim_create_augroup("LfTerminalHook", { clear = true }),
      callback = function()
        local f = io.open("/tmp/.lf_cwd", "r")
        if not f then return end
        local dir = f:read("*l")
        f:close()
        os.remove("/tmp/.lf_cwd")
        if dir and dir ~= "" then
          require("toggleterm.terminal").Terminal:new({ dir = dir, direction = "horizontal" }):toggle()
        end
      end,
    })
  end,
}
