-- =================================================================================================
--  Types
-- =================================================================================================

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


-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
local api = vim.api

---@module 'duplines.enum'
local const = require('duplines.enum')

---@module 'duplines.config'
local config = require('duplines.config')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local Line = {}
local L = {}


-- =================================================================================================
--  Function
-- =================================================================================================

-- / Constructor
-- -------------------------------------------------------------------------------------------------

---@private
function Line:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- / Helper
-- -------------------------------------------------------------------------------------------------

table.unpack = table.unpack or unpack ---@diagnostic disable-line:deprecated

L.keyseq_start_vline_mode = api.nvim_replace_termcodes('<S-V>', true, false, true)
L.keyseq_mark_begin_selection = api.nvim_replace_termcodes('m<', true, false, true)
L.keyseq_mark_end_selection = api.nvim_replace_termcodes('m>', true, false, true)
L.keyseq_esc = api.nvim_replace_termcodes('<Esc>', true, false, true)

---@return string
function L.get_mode()
  return api.nvim_get_mode().mode
end

---@return boolean
function L.is_normal_mode()
  return L.get_mode() == 'n'
end

---@return boolean
function L.is_v_line_mode()
  return L.get_mode() == 'V'
end

-- Emulates actual keystrokes to keep line selection while positioning the cursor.
-- This could not be achieved by setting the selection mark ("m<", "m>") and then executing the "gv"
-- command.
---@param on CursorPos
---@param range Range
function L.select_linewise(on, range)
  local begin_idx = {}
  local end_idx = {}

  if on == const.CURSOR_POS.head then
    begin_idx = range:pos_on_tail()
    end_idx = range:pos_on_head()
  elseif on == const.CURSOR_POS.tail then
    begin_idx = range:pos_on_head()
    end_idx = range:pos_on_tail()
  else
    begin_idx = range:pos_on_begin()
    end_idx = range:pos_on_end()
  end

  if L.is_v_line_mode then
    api.nvim_feedkeys(L.keyseq_esc, 'x', false)
  end

  -- Marks "m<" and "m>" are automatically rearranged by Vim so that their coordinates are top to
  -- bottom and left to right.
  api.nvim_win_set_cursor(0, L.to_cursor_index(begin_idx))
  local keyseq = ''
    .. L.keyseq_mark_begin_selection
    .. L.keyseq_start_vline_mode
    .. range:to_key_sequence(begin_idx, end_idx)
    .. L.keyseq_mark_end_selection
  api.nvim_feedkeys(keyseq, 'x', false)
end

---@param on CursorPos
---@param range Range
function L.set_cursor(on, range)
  local cursor_idx = {}

  if on == const.CURSOR_POS.head then
    cursor_idx = range:pos_on_head()
  elseif on == const.CURSOR_POS.tail then
    cursor_idx = range:pos_on_tail()
  else
    cursor_idx = range:pos_on_end()
  end

  if not L.is_normal_mode() then
    -- vim.cmd('normal! \\<Esc>') and vim.api.nvim_input('<Esc>') had no effect.
    api.nvim_feedkeys(L.keyseq_esc, 'x', false)
  end

  api.nvim_win_set_cursor(0, L.to_cursor_index(cursor_idx))
end

---@param index index_tuple (0,0)-Indexed.
---@return integer[] (1,0)-Indexed.
function L.to_cursor_index(index)
  return { index[1] + 1, index[2] }
end

-- / Class Method
-- -------------------------------------------------------------------------------------------------

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

function Line:duplicate()
  local params = self.params
  local range = self.range
  local row_idx_from, _ = table.unpack(range:row_index())
  local next_range = range:to_next()
  local next_range_row_idx_from, _ = table.unpack(next_range:row_index())
  local sources = api.nvim_buf_get_lines(0, row_idx_from, next_range_row_idx_from, true)

  -- Always duplicate after selection.
  api.nvim_buf_set_lines(0, next_range_row_idx_from, next_range_row_idx_from, true, sources)

  local on_src = params.target == const.TARGET.src
  local target_range = on_src and range or next_range

  if params.select then
    L.select_linewise(params.cursor, target_range)
  else
    -- Create a range for "gv" with the specified cursor placement.
    -- Note that in "deselect" mode, the selection range with "gv" is not optionally changeable.
    if not L.is_normal_mode() then
      -- If the cursor does not move from the source block, moving the "gv" selection range to the
      -- destination will result in natural behavior.
      if on_src then
        L.select_linewise(params.cursor, next_range)

      -- Even if the cursor moves to the destination block, recreate the selection range to match
      -- the "gv" selection range to the "cursor" option.
      else
        L.select_linewise(params.cursor, range)
      end
    end

    L.set_cursor(params.cursor, target_range)
  end
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
--  Export
-- =================================================================================================

return Line
