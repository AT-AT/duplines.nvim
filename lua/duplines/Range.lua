-- =================================================================================================
--  Types
-- =================================================================================================

---@alias range_index { from: integer, to: integer }
---@alias index_tuple { integer: integer, integer: integer }

-- This class only accepts and returns (0,0)-Indexed coordinate values (rows and columns).
---@class Range
---@field from_pos fun(): Range Factory (class method)
---@field col_index fun(): index_tuple
---@field key_sequence fun(self, CursorPos): string
---@field pos_on_begin fun(): index_tuple
---@field pos_on_end fun(): index_tuple
---@field pos_on_head fun(): index_tuple
---@field pos_on_tail fun(): index_tuple
---@field row_count fun(): integer
---@field row_index fun(): index_tuple
---@field to_next fun(): Range
---@field to_key_sequence fun(self, from: index_tuple, to: index_tuple): string
---@field col range_index
---@field row range_index
---@field inverted boolean


-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@module 'duplines.enum'
local const = require('duplines.enum')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local Range = {}
local L = {}


-- =================================================================================================
--  Function
-- =================================================================================================

-- / Constructor
-- -------------------------------------------------------------------------------------------------

---@private
function Range:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- / Helper
-- -------------------------------------------------------------------------------------------------

table.unpack = table.unpack or unpack ---@diagnostic disable-line:deprecated

---@param from integer
---@param to integer
---@return string
function L.to_col_keyseq(from, to)
  local delta = to - from

  if delta == 0 then
    return ''
  elseif delta > 0 then
    return delta .. 'l'
  else
    return math.abs(delta) .. 'h'
  end
end

-- / Class Method
-- -------------------------------------------------------------------------------------------------

function Range.from_pos()
  local row_num_a = vim.fn.getpos('v')[2]
  local row_num_b = vim.fn.getpos('.')[2]
  local col_num_a = vim.fn.getpos('v')[3]
  local col_num_b = vim.fn.getpos('.')[3]

  local row_idx_a = row_num_a > 0 and row_num_a - 1 or 0
  local row_idx_b = row_num_b > 0 and row_num_b - 1 or 0
  local col_idx_a = col_num_a > 0 and col_num_a - 1 or 0
  local col_idx_b = col_num_b > 0 and col_num_b - 1 or 0

  local inverted = false

  if row_idx_a > row_idx_b then
    row_idx_a, row_idx_b = row_idx_b, row_idx_a
    col_idx_a, col_idx_b = col_idx_b, col_idx_a
    inverted = true
  end

  return Range:new({
    row = { from = row_idx_a, to = row_idx_b },
    col = { from = col_idx_a, to = col_idx_b },
    inverted = inverted,
  })
end

-- / Instance Method
-- -------------------------------------------------------------------------------------------------

function Range:col_index()
  return { self.col.from, self.col.to }
end

function Range:is_inverted()
  return self.inverted
end

function Range:key_sequence(cursor_pos)
  local begin_idx = {}
  local end_idx = {}

  if cursor_pos == const.CURSOR_POS.head then
    begin_idx = self:pos_on_tail()
    end_idx = self:pos_on_head()
  elseif cursor_pos == const.CURSOR_POS.tail then
    begin_idx = self:pos_on_head()
    end_idx = self:pos_on_tail()
  else
    begin_idx = self:pos_on_begin()
    end_idx = self:pos_on_end()
  end

  local from_row, from_col = table.unpack(begin_idx)
  local to_row, to_col = table.unpack(end_idx)

  -- Single row.
  if from_row == to_row then
    return L.to_col_keyseq(from_col, to_col)
  end

  -- Vertical direction.
  local row_keyseq = ''
  local delta = to_row - from_row
  if delta > 0 then
    row_keyseq = delta .. 'j'
  else
    row_keyseq = math.abs(delta) .. 'k'
  end

  -- If col can be moved as is to the destination row, the amount of horizontal movement will simply
  -- be the difference.
  if to_col >= from_col then
    return row_keyseq .. L.to_col_keyseq(from_col, to_col)
  end

  -- Otherwise, the length of the destination row is unknown, so move via the left edge.
  return L.to_col_keyseq(from_col, 0) .. row_keyseq .. L.to_col_keyseq(0, to_col)
end

function Range:pos_on_head()
  return { self.row.from, 0 }
end

function Range:pos_on_tail()
  return { self.row.to, 0 }
end

function Range:pos_on_begin()
  local pos = self:is_inverted() and 'to' or 'from'
  return { self.row[pos], self.col[pos] }
end

function Range:pos_on_end()
  local pos = self:is_inverted() and 'from' or 'to'
  return { self.row[pos], self.col[pos] }
end

function Range:row_count()
  return self.row.to - self.row.from + 1
end

function Range:row_index()
  return { self.row.from, self.row.to }
end

function Range:to_next()
  local row_count = self:row_count()

  return Range:new({
    row = { from = self.row.from + row_count, to = self.row.to + row_count },
    col = { from = self.col.from, to = self.col.to },
    inverted = self.inverted,
  })
end


-- =================================================================================================
--  Export
-- =================================================================================================

return Range
