local ok, pk = pcall(require, "pennykit")

if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE


-- Customize None-ls sources (formatters, linters)

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
    enabled = ok and pk.is_enabled("none-ls"),
  opts = function(_, opts)
    -- local null_ls = require "null-ls"

    -- Check supported formatters and linters
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Set a formatter:
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
    })
  end,
}
