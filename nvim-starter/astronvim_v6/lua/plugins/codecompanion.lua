local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("codecompanion") then return { enabled = false } end

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local ok, cc_config = pcall(require,"codecompanion_config")
    require("codecompanion").setup((ok and cc_config) or {})
  end,
}
