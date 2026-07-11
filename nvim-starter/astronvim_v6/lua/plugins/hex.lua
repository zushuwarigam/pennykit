local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("hex") then return false end

return {
  "RaafatTurki/hex.nvim",
  cmd = { "HexDump", "HexAssemble", "HexToggle" }, -- 🔑 Lazy-load on command
  config = function()
    require("hex").setup({
      dump_cmd = "xxd -g 1 -u",
      assemble_cmd = "xxd -r",
      is_file_binary_pre_read = function(filepath)
        local f = io.open(filepath, "r")
        if not f then return false end
        local chunk = f:read(1024)
        f:close()
        -- Detect null bytes or high frequency of non-printable chars
        return chunk and (string.find(chunk, "%z") ~= nil or
          select(2, string.gsub(chunk, "[\32-\126]", "")) > 200)
      end,
    })
  end,
  -- Optional: Add keymaps
  keys = {
    { "<leader>H", "<cmd>HexToggle<cr>", desc = "Toggle Hex View" },
  },
}
