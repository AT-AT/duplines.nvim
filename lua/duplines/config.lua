-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@module 'duplines.const'
---
local const = require('duplines.const')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Definition
-- =================================================================================================

---@type string
---
M.plugin_name = 'Duplines'

---@type PluginOptions
---
M.default_options = {
  target = const.TARGET.dest,
  cursor = const.CURSOR_POS.head,
  select = false,
  event_name = M.plugin_name .. 'LineDuplicated',
}

---@type PluginOptions
---
M.options = vim.tbl_deep_extend('force', {}, M.default_options)


-- =================================================================================================
--  Function (API)
-- =================================================================================================

--- Merge the specified parameters.
---
---@param local_options PluginOptions?
---
function M.merge_options(local_options)
  local_options = local_options or {}
  M.options = vim.tbl_deep_extend('force', M.options, local_options)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
