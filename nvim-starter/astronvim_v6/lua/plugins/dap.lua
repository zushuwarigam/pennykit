return {
  "mfussenegger/nvim-dap",
  config = function(plugin, opts)
    require("astronvim.plugins.configs.nvim-dap")(plugin, opts)

    local dap = require "dap"
    local dapui = require "dapui"
    local python3_bin = vim.fn.executable("python3") == 1 and vim.fn.exepath "python3" or "/usr/bin/python3"

    --- Resolve the Python executable for debugpy.
    --- Priority: conda env "pcagent" → local venv/.venv → system python3.
    local function resolve_python()
      -- 1. Conda env (PC-Agent primary)
      local home = vim.fn.getenv "HOME"
      local conda_python = home .. "/miniconda3/envs/pcagent/bin/python"
      if vim.fn.executable(conda_python) == 1 then return conda_python end
      -- Also check anaconda3 / miniforge3
      for _, base in ipairs { "anaconda3", "miniforge3" } do
        local alt = home .. "/" .. base .. "/envs/pcagent/bin/python"
        if vim.fn.executable(alt) == 1 then return alt end
      end
      -- 2. Local virtualenv
      local cwd = vim.fn.getcwd()
      for _, dir in ipairs { "venv", ".venv" } do
        local path = cwd .. "/" .. dir .. "/bin/python"
        if vim.fn.executable(path) == 1 then return path end
      end
      -- 3. System fallback
      return python3_bin
    end

    dap.adapters.python = {
      type = "executable",
      command = python3_bin,
      args = { "-m", "debugpy.adapter" },
    }
    dap.configurations.python = {
      -- Launch the current file
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        pythonPath = resolve_python,
        console = "integratedTerminal",
        justMyCode = false,
      },
    }

    -- Load project-local debug configs from .vscode/launch.json (if present).
    -- This allows each project to define its own debug configurations while
    -- keeping the generic "Launch file" config here for all projects.
    local vscode = require "dap.ext.vscode"
    vscode.load_launchjs(nil) -- auto-detect launch.json in cwd
    -- Map launch.json "debugpy" type to our "python" adapter
    vscode.type_to_ft = { debugpy = "python" }

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
