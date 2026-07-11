-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local function load_wordlist(filename)
  local path = vim.fn.stdpath "config" .. "/spell/" .. filename
  local file = io.open(path, "r")
  if not file then return {} end
  local words = {}
  for word in file:lines() do
    table.insert(words, word)
  end
  file:close()
  return words
end

local en_words = load_wordlist "en.utf-8.add"
local ru_words = load_wordlist "ru.utf-8.add"

local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("astrolsp") then return { enabled = false } end

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      codelens = true, -- enable/disable codelens refresh on start
      inlay_hints = false, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          "c", "cpp", "go", "python",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      "ltex",
      "ltex_plus",
      "ruff",
      "basedpyright",
    },
    ---@diagnostic disable: missing-fields
    config = {
      -- ["*"] = { capabilities = {} }, -- modify default LSP client settings such as capabilities
      ltex = {
        settings = {
          ltex = {
            language = "auto",
            dictionary = {
              ["en-US"] = en_words,
              ["ru-RU"] = ru_words,
            },
            languageToolHttpServerUri = vim.env.LANGUAGE_TOOLS or "http://lt.bme.local",
            enabled = { "markdown", "text", "latex" },
            additionalRules = {
              motherTongue = "ru-RU",
            },
            checkFrequency = "save",
            diagnosticSeverity = "information",
          },
        },
      },
      clangd = { capabilities = { offsetEncoding = "utf-8" } },
      gopls = {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
              nilness = true,
              unusedwrite = true,
              useany = true,
            },
            staticcheck = true,
            gofumpt = true,
            codelenses = {
              generate = true,
              gc_details = true,
              run_govulncheck = true,
              tidy = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      },
      ruff = {
        settings = {
          enable = true,
          organizeImports = true,
        },
      },
    },
    -- customize language server configuration passed to `vim.lsp.config`
    -- client specific configuration can also go in `lsp/` in your configuration root (see `:h lsp-config`)
    -- customize how language servers are attached
    handlers = {
      -- a function with the key `*` modifies the default handler, functions takes the server name as the parameter
      -- ["*"] = function(server) vim.lsp.enable(server) end

      -- the key is the server that is being setup with `vim.lsp.config`
      -- rust_analyzer = false, -- setting a handler to false will disable the set up of that language server
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        -- Optional condition to create/delete auto command group
        -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
        -- condition will be resolved for each client on each execution and if it ever fails for all clients,
        -- the auto commands will be deleted for that buffer
        cond = "textDocument/codeLens",
        -- cond = function(client, bufnr) return client.name == "lua_ls" end,
        -- list of auto commands to set
        {
          -- events to trigger
          event = { "InsertLeave", "BufEnter" },
          -- the rest of the autocmd options (:h nvim_create_autocmd)
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    -- takes two parameters `client` and `bufnr`  (`:h lsp-attach`)
    on_attach = function(client, bufnr)
      -- this would disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}
