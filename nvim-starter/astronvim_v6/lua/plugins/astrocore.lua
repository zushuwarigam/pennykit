-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("astrocore") then return { enabled = false } end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = true, -- sets vim.opt.spell
        spelllang = { "en_us", "ru_yo" },
        spellsuggest = "best,9",
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false, -- sets vim.opt.wrap
        mouse = 'a',
        langmap = {
          "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ",
          "фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz",
        },
      },
      g = {
        clipboard = "osc52",
        editorconfig = true,
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,
        ["<leader>p"] = { name = "PennyKit/Plugins" },
        ["<leader>a"] = { name = "AI/CodeCompanion" },
        ["<Leader>aa"] = { "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle Chat" },
        ["<Leader>ap"] = { "<cmd>CodeCompanionActions<cr>", desc = "Action Palette" },
        -- Plugin Manager (Telescope-based)
        ["<Leader>pp"] = { "<cmd>PKPlugins<cr>", desc = "PennyKit plugins" },
        ["<Leader>pa"] = { "<cmd>PKPluginAdd<cr>", desc = "Add plugin" },
        ["<Leader>ps"] = { "<cmd>PKPluginSync<cr>", desc = "Sync plugins" },
        ["<Tab>"] = { "<cmd>bnext<CR>", desc = "Next buffer" },
        ["<S-Tab>"] = { "<cmd>bprev<CR>", desc = "Previous buffer" },
        ["<M-Up>"] = { function() vim.cmd("resize +2") end, desc = "Increase window height" },
        ["<M-Down>"] = { function() vim.cmd("resize -2") end, desc = "Decrease window height" },
        ["<M-Left>"] = { function() vim.cmd("vertical resize -2") end, desc = "Decrease window width" },
        ["<M-Right>"] = { function() vim.cmd("vertical resize +2") end, desc = "Increase window width" },
      },
      v = {
        ["<Leader>aa"] = { "<cmd>CodeCompanionChat<cr>", desc = "Add to Chat" },
      },
    },

  },
}
