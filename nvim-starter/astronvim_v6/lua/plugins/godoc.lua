local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("godoc") then return { enabled = false } end

---@type LazySpec
return {
  -- Godoc
  {
    "fredrikaverpil/godoc.nvim",
    version = "*",
    dependencies = {
      { "nvim-telescope/telescope.nvim" }, -- optional
      { "folke/snacks.nvim" }, -- optional
      { "echasnovski/mini.pick" }, -- optional
      { "ibhagwan/fzf-lua" }, -- optional
      {
        "nvim-treesitter/nvim-treesitter",
        opts = {
          ensure_installed = { "go" },
        },
      },
    },
    build = "go install github.com/lotusirous/gostdsym/stdsym@latest", -- optional
    cmd = { "GoDoc" }, -- optional
    opts = {
      adapters = {
        -- for details, see lua/godoc/adapters/go.lua
        {
          name = "go",
          opts = {
            command = "GoDoc", -- the vim command to invoke Go documentation
            get_syntax_info = function()
              return {
                filetype = "godoc", -- filetype for the buffer
                language = "go", -- tree-sitter parser, for syntax highlighting
              }
            end,
          },
        },
      },
      window = {
        type = "vsplit", -- split | vsplit
      },
      picker = {
        type = "telescope", -- native (vim.ui.select) | telescope | snacks | mini | fzf_lua

        -- see respective picker in lua/godoc/pickers for available options
        native = {},
        telescope = {},
        snacks = {},
        mini = {},
        fzf_lua = {},
      },
    }, -- see further down below for configuration
  },
}
