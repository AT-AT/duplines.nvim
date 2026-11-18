-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.fn
---
local fn = vim.fn


-- =================================================================================================
--  Namespace
-- =================================================================================================

local Range = {}


-- =================================================================================================
--  Method
-- =================================================================================================

-- / Constructor
-- -------------------------------------------------------------------------------------------------

--- Constructor.
---
---@private
---@return Range
---
function Range:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- / Class Method
-- -------------------------------------------------------------------------------------------------

--- Create a Range object from the current target row or the selected range.
---
function Range.from_pos()
  local pos_a = fn.getpos('v')
  local pos_b = fn.getpos('.')

  local row_num_a = pos_a[2]
  local row_num_b = pos_b[2]
  local col_num_a = pos_a[3]
  local col_num_b = pos_b[3]

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

--- Get the indices for the start and end columns.
---
function Range:col_index()
  return { self.col.from, self.col.to }
end

--- Determine whether the selection direction is inverted.
---
function Range:is_inverted()
  return self.inverted
end

--- Get the index of the starting row of the selection.
---
function Range:pos_on_begin()
  local pos = self:is_inverted() and 'to' or 'from'
  return { self.row[pos], self.col[pos] }
end

--- Get the index of the end row of the selection.
---
function Range:pos_on_end()
  local pos = self:is_inverted() and 'from' or 'to'
  return { self.row[pos], self.col[pos] }
end

--- Get the index of the start row.
---
function Range:pos_on_head()
  return { self.row.from, 0 }
end

--- Get the index of the end row.
---
function Range:pos_on_tail()
  return { self.row.to, 0 }
end

--- Get the number of rows.
---
function Range:row_count()
  return self.row.to - self.row.from + 1
end

--- Get the indices for the start and end rows.
---
function Range:row_index()
  return { self.row.from, self.row.to }
end

--- Create a Range object for the destination.
---
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
