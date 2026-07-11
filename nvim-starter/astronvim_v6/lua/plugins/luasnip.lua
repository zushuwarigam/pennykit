local ok, pk = pcall(require, "pennykit")

-- LuaSnip Custom Configuration

---@type LazySpec
return {
  {
    "L3MON4D3/LuaSnip",
    enabled = ok and pk.is_enabled("luasnip"),
    config = function(plugin, opts)
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
    end,
  },
}
