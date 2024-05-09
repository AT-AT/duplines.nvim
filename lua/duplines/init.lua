-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@module 'duplines.config'
local config = require('duplines.config')

---@module 'duplines.Line'
local Line = require('duplines.Line')

---@module 'duplines.Range'
local Range = require('duplines.Range')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local API = {}


-- =================================================================================================
--  Function (API)
-- =================================================================================================

---@param params PluginOptions?
---@return Line
function API.line(params)
  return Line.on_range(Range.from_pos(), params or {})
end

---@param local_options PluginOptions?
function API.setup(local_options)
  config.merge_options(local_options or {})
end


-- =================================================================================================
--  Export
-- =================================================================================================

return {
  line = API.line,
  setup = API.setup,
}
