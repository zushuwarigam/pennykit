-- ~/.config/astronvim/lua/plugins/go.lua
local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("go") then return {} end

return {
  "ray-x/go.nvim",
  dependencies = { "ray-x/guihua.lua" },
  ft = { "go", "gomod", "gosum", "gowork" },   -- lazy load on Go files
  build = ':lua require("go.install").update_all_sync()',
  opts = {
    go          = "go",
    goimports   = "gopls",
    gofmt       = "gofumpt",
    lsp_inlay_hints = { enable = true },
    luasnip     = true,
    dap_debug   = true,
    trouble     = true,       -- use trouble.nvim for diagnostics if installed
    test_runner = "go",       -- or "richgo", "gotestsum"
    run_in_floaterm = true,   -- run/test output in floating terminal
  },
}
