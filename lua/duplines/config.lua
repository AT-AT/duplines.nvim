-- =================================================================================================
--  Types
-- =================================================================================================

-- https://github.com/LuaLS/lua-language-server/discussions/1436#discussioncomment-3318346
---@class PluginOptions
---@field cursor CursorPos
---@field select boolean
---@field target Target


-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@module 'duplines.enum'
local const = require('duplines.enum')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Function
-- =================================================================================================

---@type PluginOptions
M.default_options = {
  target = const.TARGET.dest,
  cursor = const.CURSOR_POS.head,
  select = false,
}

---@type PluginOptions
M.options = vim.tbl_deep_extend('force', {}, M.default_options)

---@param local_options PluginOptions?
function M.merge_options(local_options)
  local_options = local_options or {}
  M.options = vim.tbl_deep_extend('force', M.options, local_options)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
