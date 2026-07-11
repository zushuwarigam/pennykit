local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("dap") then return {} end

return {
  "mfussenegger/nvim-dap",
  config = function(plugin, opts)
    require("astronvim.plugins.configs.nvim-dap")(plugin, opts)

    local dap = require "dap"
    local dapui = require "dapui"
    local python3_bin = vim.fn.executable("python3") == 1 and vim.fn.exepath("python3") or "/usr/bin/python3"

    dap.adapters.python = {
      type = "executable",
      command = python3_bin,
      args = { "-m", "debugpy.adapter" },
    }
    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        pythonPath = function()
          local cwd = vim.fn.getcwd()
          for _, dir in ipairs { "venv", ".venv" } do
            local path = cwd .. "/" .. dir .. "/bin/python"
            if vim.fn.executable(path) == 1 then return path end
          end
          return python3_bin
        end,
      },
    }

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
      },
    }
    local cpp_cfg = {
      name = "Launch with codelldb",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
    }
    dap.configurations.cpp = vim.list_extend(dap.configurations.cpp or {}, { cpp_cfg })
    dap.configurations.c = vim.list_extend(dap.configurations.c or {}, { cpp_cfg })

    vim.keymap.set("n", "<leader>dt", dapui.toggle, { desc = "Toggle DAP UI" })
    vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "Evaluate expression" })
    vim.keymap.set("n", "<leader>dr", dap.run_last, { desc = "Run last" })
  end,
}
