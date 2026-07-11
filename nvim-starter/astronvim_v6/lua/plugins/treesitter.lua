-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("treesitter") then return {} end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      ensure_installed = {
        "bash",
        "css",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "html",
        "javascript",
        "latex",
        "lua",
        "regex",
        "scss",
        "svelte",
        "tsx",
        "typst",
        "vim",
        "c",
        "cpp",
        "python",
        "vimdoc",
        "query",
        "luadoc",
      },
    },
  },
}
