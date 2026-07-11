local ok, pk = pcall(require, "pennykit")

-- Discord Rich Presence

---@type LazySpec
return {
  "andweeb/presence.nvim",
    enabled = ok and pk.is_enabled("presence"),
}
