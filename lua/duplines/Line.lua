-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
---
local api = vim.api

---@module 'duplines.config'
---
local config = require('duplines.config')

---@module 'duplines.const'
---
local const = require('duplines.const')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local Line = {}
local L = {}


-- =================================================================================================
--  Definition
-- =================================================================================================

table.unpack = table.unpack or unpack ---@diagnostic disable-line:deprecated

---@type string
---
L.keyseq_start_vline_mode = api.nvim_replace_termcodes('<S-V>', true, false, true)
L.keyseq_mark_begin_selection = api.nvim_replace_termcodes('m<', true, false, true)
L.keyseq_mark_end_selection = api.nvim_replace_termcodes('m>', true, false, true)
L.keyseq_esc = api.nvim_replace_termcodes('<Esc>', true, false, true)


-- =================================================================================================
--  Method
-- =================================================================================================

-- / Constructor
-- -------------------------------------------------------------------------------------------------

--- Constructor.
---
---@private
---@return Line
---
function Line:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- / Class Method
-- -------------------------------------------------------------------------------------------------

--- Create a Line object for the target range.
---
function Line.on_range(range, params)
  params = params or {}

  if not vim.tbl_contains(vim.tbl_values(const.TARGET), params.target) then
    params.target = nil
  end

  if not vim.tbl_contains(vim.tbl_values(const.CURSOR_POS), params.cursor) then
    params.cursor = nil
  end

  params = vim.tbl_deep_extend('force', config.options, params)

  return Line:new({
    range = range,
    params = params,
  })
end

-- / Instance Method
-- -------------------------------------------------------------------------------------------------

--- Duplicate the rows in the target range.
---
function Line:duplicate()
  local params = self.params
  local range = self.range
  local row_idx_from, row_idx_to = table.unpack(range:row_index())
  local next_range = range:to_next()
  local next_range_row_idx_from, next_range_row_idx_to = table.unpack(next_range:row_index())
  local sources = api.nvim_buf_get_lines(0, row_idx_from, next_range_row_idx_from, true)

  -- Always duplicate after selection.
  api.nvim_buf_set_lines(0, next_range_row_idx_from, next_range_row_idx_from, true, sources)

  local on_src = params.target == const.TARGET.src
  local target_range = on_src and range or next_range

  -- When the cursor is positioned on the source side (such as when performing a pseudo-upward
  -- duplication), the mark should be placed on the destination side. Therefore, the source—which
  -- currently holds the mark—and the destination should be swapped.
  if on_src then
    vim.cmd({
      cmd = 'move',
      range = { row_idx_from + 1, row_idx_to + 1 },
      args = { next_range_row_idx_to + 1 },
    })
  end

  if params.select then
    L.select_linewise(params.cursor, target_range)
  else
    -- Create a range for "gv" with the specified cursor placement.
    -- This plugin ALWAYS inserts the duplicated lines immediately after the original lines, so the
    -- following behavior is natural.
    if not L.is_normal_mode() then
      -- When the cursor is placed in the source block, it is probably to express the behavior of
      -- "copying upwards," so it is natural that the selection range by "gv" is in the destination
      -- block.
      if on_src then
        L.select_linewise(params.cursor, next_range)

      -- When the cursor is placed in the destination block, it is probably to express the behavior
      -- of "copying downwards," so it is natural that the selection range by "gv" is in the source
      -- block.
      else
        L.select_linewise(params.cursor, range)
      end
    end

    L.send_escape()
  end

  L.set_cursor_to_final_pos(params.cursor, target_range)
end

-- / Instance Method (Parameter Wrapper)
-- -------------------------------------------------------------------------------------------------

function Line:dest()
  self.params.target = const.TARGET.dest

  return self
end

function Line:deselect()
  self.params.select = false

  return self
end

function Line:head()
  self.params.cursor = const.CURSOR_POS.head

  return self
end

function Line:keep()
  self.params.cursor = const.CURSOR_POS.keep

  return self
end

function Line:select()
  self.params.select = true

  return self
end

function Line:src()
  self.params.target = const.TARGET.src

  return self
end

function Line:tail()
  self.params.cursor = const.CURSOR_POS.tail

  return self
end


-- =================================================================================================
--  Function (Helper)
-- =================================================================================================

--- Get the current mode.
---
---@private
---@return string
---
function L.get_mode()
  return api.nvim_get_mode().mode
end

--- Determine whether the current mode is Normal mode.
---
---@private
---@return boolean
---
function L.is_normal_mode()
  return L.get_mode() == 'n'
end

--- Determine whether the current mode is V-Line mode.
---
---@private
---@return boolean
---
function L.is_v_line_mode()
  return L.get_mode() == 'V'
end

--- Select by row.
---
---@private
---@param on CursorPos
---@param range Range
---
function L.select_linewise(on, range)
  local begin_pos = {}
  local end_pos = {}

  -- To set the cursor while remaining in visual-line mode, the end point of the selection must be
  -- the same as the final position of the cursor.
  if on == const.CURSOR_POS.head then
    begin_pos = range:pos_on_tail()
    end_pos = range:pos_on_head()
  elseif on == const.CURSOR_POS.tail then
    begin_pos = range:pos_on_head()
    end_pos = range:pos_on_tail()
  else
    begin_pos = range:pos_on_begin()
    end_pos = range:pos_on_end()
  end

  if L.is_v_line_mode then
    L.send_escape()
  end

  api.nvim_win_set_cursor(0, L.to_cursor_index(begin_pos))
  api.nvim_feedkeys(L.keyseq_mark_begin_selection, 'x', false)

  vim.cmd('normal! V')

  api.nvim_win_set_cursor(0, L.to_cursor_index(end_pos))
  api.nvim_feedkeys(L.keyseq_mark_end_selection, 'x', false)
end

--- Send an escape sequence.
---
---@private
---
function L.send_escape()
  -- vim.cmd('normal! \\<Esc>') and vim.api.nvim_input('<Esc>') had no effect.
  api.nvim_feedkeys(L.keyseq_esc, 'x', false)
end

--- Set the cursor to the final position.
---
---@private
---@param on CursorPos
---@param range Range
---
function L.set_cursor_to_final_pos(on, range)
  local cursor_idx = {}

  if on == const.CURSOR_POS.head then
    cursor_idx = range:pos_on_head()
  elseif on == const.CURSOR_POS.tail then
    cursor_idx = range:pos_on_tail()
  else
    cursor_idx = range:pos_on_end()
  end

  api.nvim_win_set_cursor(0, L.to_cursor_index(cursor_idx))
end

--- Convert the internal coordinates of a Range object into cursor coordinates.
---
---@private
---@param index index_tuple (0,0)-Indexed.
---@return integer[] (1,0)-Indexed.
---
function L.to_cursor_index(index)
  return { index[1] + 1, index[2] }
end


-- =================================================================================================
--  Export
-- =================================================================================================

return Line
