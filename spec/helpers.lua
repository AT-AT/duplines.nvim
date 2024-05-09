local assert = require('luassert')
local helper = require('vusted.helper')
local say = require('say')

local M = {}

-- / Alias
-- -------------------------------------------------------------------------------------------------

M.assert = assert -- Suppress diagnostics warnings for luassert globally imported by busted.
M.cleanup = helper.cleanup
M.cleanup_modules = helper.cleanup_loaded_modules

-- / Custom Assertion
-- -------------------------------------------------------------------------------------------------

local function is_vline_mode(_)
  return vim.api.nvim_get_mode().mode == 'V'
end

say:set('assertion.is_vline_mode.positive', 'Expected mode is V-LINE')
say:set('assertion.is_vline_mode.negative', 'Expected mode is not V-LINE')
assert:register(
  'assertion',
  'is_vline_mode', is_vline_mode,
  'assertion.is_vline_mode.positive', 'assertion.is_vline_mode.negative'
)

local function is_vline_start_row(_, arguments)
  local expected = arguments[1]
  local actual = M.select_start_pos()

  -- When running a test, col of mark "m<" by function getpos() is always 0, and at this point it is
  -- not possible to emulate the value caused by the actual operation.
  return actual[1] == expected[1] and actual[2] == 0
end

say:set('assertion.is_vline_start_row.positive', 'Expected %s is the same as "m<"')
say:set('assertion.is_vline_start_row.negative', 'Expected %s is not the same as "m<"')
assert:register(
  'assertion',
  'is_vline_start_row', is_vline_start_row,
  'assertion.is_vline_start_row.positive', 'assertion.is_vline_start_row.negative'
)

local function is_vline_end_row(_, arguments)
  local expected = arguments[1]
  local actual = M.select_end_pos()

  -- As above, col of mark "m>" by function getpos() is always v:maxcol.
  return actual[1] == expected[1] and actual[2] == vim.v.maxcol - 1
end

say:set('assertion.is_vline_end_row.positive', 'Expected %s is the same as "m<"')
say:set('assertion.is_vline_end_row.negative', 'Expected %s is not the same as "m<"')
assert:register(
  'assertion',
  'is_vline_end_row', is_vline_end_row,
  'assertion.is_vline_end_row.positive', 'assertion.is_vline_end_row.negative'
)

-- / Utility (Environment)
-- -------------------------------------------------------------------------------------------------

function M.mock_config_option(key, value)
  local map = type(key) == 'table' and key or { [key] = value }
  local options_ref = require('duplines.config').options

  for k, v in pairs(map) do
    options_ref[k] = v
  end
end

-- / Utility (Arrangement)
-- -------------------------------------------------------------------------------------------------

M.vline_keycode = vim.api.nvim_replace_termcodes('<S-V>', true, false, true)

-- NOTE: Implicitly refer to current buffer/window.
-- If the first element of arguments is an integer, it is treated as the starting row "number"
-- (1-Base).
function M.prepare_rows(...)
  local lines = { ... }
  local pad_count = 0

  if vim.tbl_count(lines) > 0 and type(lines[1]) == 'integer' then
    pad_count = lines[1] - 1
    table.remove(lines, 1)
  end

  if vim.tbl_count(lines) == 0 then
    lines = { 'foo', 'bar', 'baz' }
  end

  if pad_count > 0 then
    for _ = 1, pad_count do
      table.insert(lines, 1, '')
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, 0, true, lines)
  vim.api.nvim_buf_set_lines(0, -2, -1, true, {}) -- Remove last empty line from the begining.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- NOTE: Implicitly refer to current buffer.
function M.lines_on(from_idx, to_idx)
  return vim.api.nvim_buf_get_lines(0, from_idx, to_idx + 1, true) -- (1->N/Excluded)
end

-- NOTE: Implicitly refer to current window.
function M.cursor_to(row_idx, col_idx)
  vim.api.nvim_win_set_cursor(0, { row_idx + 1, col_idx }) -- (1,0)-Indexed
end

-- NOTE: Implicitly refer to current window.
function M.cursor_pos()
  local pos = vim.api.nvim_win_get_cursor(0) -- (1,0)-Indexed
  return { pos[1] - 1, pos[2] } -- (0,0)-Indexed
end

function M.get_pos(expr)
  local pos = vim.fn.getpos(expr) -- (1,1)-Indexed
  return { pos[2] - 1, pos[3] - 1 } -- (0,0)-Indexed
end

function M.select_start_pos()
  return M.get_pos("'<")
end

function M.select_end_pos()
  return M.get_pos("'>")
end

function M.to_range_index(a, b)
  return { from = a, to = b }
end

-- / Utility (Runner)
-- -------------------------------------------------------------------------------------------------

function M.wait_for(kick, after)
  local done = false

  vim.defer_fn(function ()
    after()
    done = true
  end, 50)

  kick()
  vim.wait(500, function() return done end, 100)
end

-- / Utility (Inspection)
-- -------------------------------------------------------------------------------------------------

function M.print(thing)
  vim.api.nvim_echo({ { tostring(thing) .. "\n" } }, false, {})
end

function M.dump(thing)
  M.print('----------')
  M.print(M.to_string(thing))
  M.print('----------')
end

function M.to_string(thing)
  if type(thing) == 'table' then
    local joined = '{ '

    for k, v in pairs(thing) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      joined = joined .. '['.. k ..'] = ' .. M.to_string(v) .. ','
    end

    return joined .. ' }'
  elseif thing == nil then
    return 'nil'
  else
    return tostring(thing)
  end
end

return M
