-- Dump all keymaps with descriptions from the current Neovim config
-- Usage: nvim --headless -c "luafile scripts/dump_keymaps.lua" -c "qa"

local out_path = "/tmp/nvim-keymaps.md"
local out = io.open(out_path, "w")
if not out then
  print("ERROR: cannot open " .. out_path)
  return
end

local results = {}
local modes = { "n", "v", "x", "s", "o", "t", "i", "c", "l" }

for _, mode in ipairs(modes) do
  local keymaps = vim.api.nvim_get_keymap(mode)
  for _, km in ipairs(keymaps) do
    if km.desc and km.desc ~= "" then
      local lhs = vim.fn.keytrans(km.lhs)
      lhs = lhs:gsub("<Leader>", "SPC")
      table.insert(results, {
        mode = mode,
        lhs = lhs,
        desc = km.desc,
      })
    end
  end
end

-- Deduplicate
local seen = {}
local unique = {}
for _, r in ipairs(results) do
  local key = r.lhs .. "|" .. r.desc
  if not seen[key] then
    seen[key] = true
    table.insert(unique, r)
  end
end

table.sort(unique, function(a, b)
  if #a.lhs ~= #b.lhs then return #a.lhs < #b.lhs end
  return a.lhs < b.lhs
end)

-- Categorization
local categories = {
  { patterns = { "gitsigns", "lazygit", "diffview" }, cat = "Git" },
  { patterns = { "dap", "debug" }, cat = "Debug" },
  { patterns = { "neotest" }, cat = "Test" },
  { patterns = { "trouble", "diagnosti" }, cat = "Diagnostics" },
  { patterns = { "telescope", "fzf%-lua", "snacks%.picker" }, cat = "Search" },
  { patterns = { "toggleterm", "terminal" }, cat = "Terminal" },
  { patterns = { "codecompanion" }, cat = "AI" },
  { patterns = { "hex" }, cat = "Hex" },
  { patterns = { "markdown" }, cat = "Markdown" },
  { patterns = { "zen" }, cat = "Zen" },
  { patterns = { "languagetool" }, cat = "Writing" },
  { patterns = { "conform", "format" }, cat = "Format" },
  { patterns = { "oil", "neo%-tree", "lf " }, cat = "File" },
  { patterns = { "which%-key" }, cat = "Which-key" },
  { patterns = { "LSP:", "lsp ", "definition", "references", "rename", "declaration", "hover", "code action", "toggle " }, cat = "LSP" },
  { patterns = { "buffer", "window", "tmux", "resize", "focus" }, cat = "Window/Buffer" },
}

local function categorize(desc)
  local d = desc:lower()
  for _, rule in ipairs(categories) do
    for _, p in ipairs(rule.patterns) do
      if d:find(p) then return rule.cat end
    end
  end
  return "Other"
end

local by_cat = {}
local cat_order = {}
for _, r in ipairs(unique) do
  local cat = categorize(r.desc)
  if not by_cat[cat] then
    by_cat[cat] = {}
    table.insert(cat_order, cat)
  end
  table.insert(by_cat[cat], r)
end

out:write("# Keymap Reference (AstroNvim)\n")
out:write("\n")

for _, cat in ipairs(cat_order) do
  local items = by_cat[cat]
  if #items == 0 then goto continue end
  out:write("## " .. cat .. "\n")
  out:write("\n")
  out:write("| Key | Action | Mode |\n")
  out:write("|-----|--------|------|\n")
  for _, r in ipairs(items) do
    local display = r.lhs:gsub("<", "&lt;"):gsub(">", "&gt;")
    out:write("| `" .. display .. "` | " .. r.desc .. " | " .. r.mode .. " |\n")
  end
  out:write("\n")
  ::continue::
end

out:close()
print("Keymaps written to " .. out_path)
