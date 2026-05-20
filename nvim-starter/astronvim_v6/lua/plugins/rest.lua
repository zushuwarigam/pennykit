return {
  "rest-nvim/rest.nvim",
  ft = "http",
  build = false,  -- ⭐ Skip luarocks build entirely
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
    "nvim-neotest/nvim-nio",
    -- Manually handle xml2lua since lazy.nvim doesn't parse its rockspec
    {
      "manoelcampos/xml2lua",
      config = function(plugin)
        package.path = package.path .. ";" .. plugin.dir .. "/?.lua"
      end,
    },
    "lunarmodules/lua-mimetypes",
  },
  opts = {
    -- Your rest.nvim config here
    result = {
      show_url = true,
      show_time = true,
    },
  },
}
