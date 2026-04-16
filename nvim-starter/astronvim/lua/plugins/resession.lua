return {
  "stevearc/resession.nvim",
  config = function()
    require("resession").setup({
      opts = {
        extensions = {
          astrocore = {}, -- REQUIRED for AstroNvim features (like tab-local buffers)
        },
        autosave = {
          enabled = false, -- standard resession autosave (usually handled by AstroCore)
          interval = 60,
          notify = true,
        },
        options = {
          "binary",
          "bufhidden",
          "buflisted",
          "cmdheight",
          "diff",
          "filetype",
          "modifiable",
          "previewwindow",
          "readonly",
          "scrollbind",
          "winfixheight",
          "winfixwidth",
        },
      },
    });
  end,
}
