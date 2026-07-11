local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("gruvbox-material") then return { enabled = false } end

local ok, theme = pcall(require, "_local_theme")
if ok and theme.colorscheme ~= "gruvbox-material" then return {} end
return {
    {
      'sainnhe/gruvbox-material',
      lazy = false,
      priority = 1000,
      config = function()
        -- Optionally configure and load the colorscheme
        -- directly inside the plugin declaration.
        vim.g.gruvbox_material_enable_italic = true
      end
    },
}
