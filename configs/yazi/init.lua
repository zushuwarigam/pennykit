-- Load plugins
-- require("git"):setup()           -- git status in manager
-- require("fzf"):setup()           -- fzf jump  (z f)
-- require("rg"):setup()            -- ripgrep   (z g)

-- Smart enter: open files, enter dirs
-- (already handled by keymap "enter" but kept for reference)

-- Show symlink target in status bar
-- function Status:name()
--   local h = cx.active.current.hovered
--   if not h then return ui.Line({}) end
--
--   local linked = ""
--   if h.link_to then
--     linked = " -> " .. tostring(h.link_to)
--   end
--   return ui.Line(" " .. h.name .. linked)
-- end
