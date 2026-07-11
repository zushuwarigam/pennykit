local ok, pk = pcall(require, "pennykit")


return {
  "rest-nvim/rest.nvim",
    enabled = ok and pk.is_enabled("rest"),
  ft = "http",
  build = false,
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        table.insert(opts.ensure_installed, "http")
      end,
    },
    "j-hui/fidget.nvim",
    "nvim-neotest/nvim-nio",
    {
      "manoelcampos/xml2lua",
      config = function(plugin)
        package.path = package.path .. ";" .. plugin.dir .. "/?.lua"
      end,
    },
    "lunarmodules/lua-mimetypes",
  },
  config = function()
    vim.g.rest_nvim = {
      result = {
        show_url = true,
        show_time = true,
      },
    }
  end,
}
