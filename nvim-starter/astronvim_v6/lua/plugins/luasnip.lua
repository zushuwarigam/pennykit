-- LuaSnip Custom Configuration
local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("luasnip") then return { enabled = false } end

---@type LazySpec
return {
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
    end,
  },
}
