-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@module 'duplines.config'
---
local config = require('duplines.config')

---@module 'duplines.Line'
---
local Line = require('duplines.Line')

---@module 'duplines.Range'
---
local Range = require('duplines.Range')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Function (API)
-- =================================================================================================

--- Setup.
---
---@param local_options PluginOptions?
---
function M.setup(local_options)
  config.merge_options(local_options or {})
end

-- -------------------------------------------------------------------------------------------------

--- Generate a Line class object that performs the duplication process.
---
---@param params PluginOptions?
---@return Line
---
function M.line(params)
  return Line.on_range(Range.from_pos(), params or {})
end


-- =================================================================================================
--  Export
-- =================================================================================================

return {
  line = M.line,
  setup = M.setup,
}
