local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("rest") then return false end

return {
  "rest-nvim/rest.nvim",
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
