-- Discord Rich Presence
local ok, pk = pcall(require, "pennykit")
if ok and not pk.is_enabled("presence") then return { enabled = false } end

---@type LazySpec
return {
  "andweeb/presence.nvim",
}
