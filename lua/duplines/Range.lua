-- =================================================================================================
--  Types
-- =================================================================================================

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


-- =================================================================================================
--  Namespace
-- =================================================================================================

local Range = {}


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

-- / Class Method
-- -------------------------------------------------------------------------------------------------

function Range.from_pos()
  local row_num_a = vim.fn.getcharpos('v')[2]
  local row_num_b = vim.fn.getcharpos('.')[2]
  local col_num_a = vim.fn.getcharpos('v')[3]
  local col_num_b = vim.fn.getcharpos('.')[3]

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
