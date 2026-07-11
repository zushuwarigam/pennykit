if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("languagetool") then return {} end

return {
  "liba2k/languagetool.nvim",
  opts = {
    server_url = vim.env.LANGUAGE_TOOLS or "http://lt.bme.local",
    language = "en-US"
  },
  keys = {
    { "<leader>lc", "<cmd>LTCheck<cr>", desc = "Check line" },
    { "<leader>lc", ":LTCheck<cr>", mode = "v", desc = "Check selection" },
    { "<leader>lb", "<cmd>LTCheckBuffer<cr>", desc = "Check buffer" },
    { "<leader>lf", "<cmd>LTFix<cr>", desc = "Show fixes" },
    { "<leader>lx", "<cmd>LTClear<cr>", desc = "Clear diagnostics" },
  },
}
