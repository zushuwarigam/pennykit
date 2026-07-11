-- Customize Mason

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("mason") then return {} end

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        -- install formatters
        "stylua",
        "ruff",
        -- install debuggers
        "debugpy",
        -- install any other package
        "tree-sitter-cli",
        -- docker
        "docker-language-server",
        "dockerfile-language-server",
        -- "docker-compose-langserver", FIX: Don't installed
        -- bash
        "bash-language-server",
        "beautysh",
        -- c/cpp
        "cpptools",
        "codelldb",
        -- go
        "gopls",
        "gofumpt",
        "golangci-lint",
        "golangci-lint-langserver",
        "gomodifytags",
        "impl",
        "delve",
        -- ltex
        "ltex-ls",
        "ltex-ls-plus",
      },
    },
  },
}
