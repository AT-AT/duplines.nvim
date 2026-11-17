-- =================================================================================================
--  Types
-- =================================================================================================

-- https://github.com/LuaLS/lua-language-server/discussions/1436#discussioncomment-3318346
---@class PluginOptions
---@field cursor CursorPos
---@field select boolean
---@field target Target

---@alias index_tuple { integer: integer, integer: integer }

---@alias range_index { from: integer, to: integer }

-- This class only accepts and returns (0,0)-Indexed coordinate values (rows and columns).
---@class Range
---@field from_pos fun(): Range Factory (class method)
---@field col_index fun(): index_tuple
---@field pos_on_begin fun(): index_tuple
---@field pos_on_end fun(): index_tuple
---@field pos_on_head fun(): index_tuple
---@field pos_on_tail fun(): index_tuple
---@field row_count fun(): integer
---@field row_index fun(): index_tuple
---@field to_next fun(): Range
---@field col range_index
---@field row range_index
---@field inverted boolean

---@class Line
---@field on_range fun(range: Range, params: PluginOptions?): Line Factory (class method)
---@field dest fun(): self
---@field deselect fun(): self
---@field duplicate fun()
---@field head fun(): self
---@field keep fun(): self
---@field select fun(): self
---@field src fun(): self
---@field tail fun(): self
---@field range Range
---@field params PluginOptions
