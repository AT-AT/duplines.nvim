-- Should clearing the module cache before loading this module.
--   package.loaded['tests/helpers'] = nil
--   local H = require('tests/helpers')
-- The reasons are as follows:
-- - In Lua and Neovim, required modules are cached until the process terminates.
-- - Because the "execution" of each test is performed in a child process, the tested module is
--   loaded for each test case, and the latest state is reflected.
-- - On the other hand, since this module is loaded in the process executing the test, the cache is
--   used and any changes to the implementation will not be reflected unless the current Neovim is
--   terminated.

local Helpers = {}

-- / Child Process Handling
-- -------------------------------------------------------------------------------------------------

---@class MiniTest.child
---@field setup function
---@field change_config function
---@field config_of function
---@field prepare_rows function
---@field lines_on function
---@field cursor_pos function
---@field get_visual_pos function

function Helpers.new_child_neovim(path)
  local child = MiniTest.new_child_neovim()

  function child.setup()
    child.restart({'-u', 'scripts/minimal_init.lua'})
    child.bo.readonly = false
    child.lua([[CONFIG_REF = require('duplines.config')]])
    child.lua([[OPTION_REF = CONFIG_REF.options]])
    child.lua("SUT = require('" .. tostring(path) .. "')")
  end

  -- / Configuration Helper
  -- -----------------------------------------------------------------------------------------------

  function child.change_config(expression)
    child.lua('OPTION_REF.' .. expression)
  end

  function child.config_of(name)
    return child.lua_get('CONFIG_REF.' .. name)
  end

  -- / Staging Helper
  -- -----------------------------------------------------------------------------------------------

  -- Note:
  --  - Each element of the list = each word will be on a new line.
  --  - After inserting words, the cursor is set to (1, 0) = (1st row, 1st column).
  function child.prepare_rows(...)
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

    child.api.nvim_buf_set_lines(0, 0, 0, true, lines)

    -- Remove the blank lines that existed when the buffer was created.
    child.api.nvim_buf_set_lines(0, -2, -1, true, {})

    child.api.nvim_win_set_cursor(0, { 1, 0 })
  end

  -- / Assertion Helper
  -- -----------------------------------------------------------------------------------------------

  -- NOTE:
  --  - Even multi-byte characters are processed and considered as bytes, so byte-represented APIs
  --    can be used.

  function child.cursor_pos()
    -- See comments in this section.
    local pos = child.api.nvim_win_get_cursor(0) -- (1,0)-indexed

    return { pos[1] - 1, pos[2] } -- (0,0)-indexed
  end

  function child.get_visual_pos()
    -- See comments in this section.
    local start_pos = child.fn.getpos('v')
    local start_row, start_col = start_pos[2], start_pos[3] - 1

    -- See comments in this section.
    local end_pos = child.api.nvim_win_get_cursor(0)
    local end_row, end_col = end_pos[1], end_pos[2]

    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end

    return { { start_row - 1, start_col }, { end_row - 1, end_col } } -- (0,0)-indexed
  end

  function child.lines_on(from, to)
    return child.api.nvim_buf_get_lines(0, from, to + 1, true) -- 0-based, end-exclusive
  end

  return child
end

-- / Custom Expectation
-- -------------------------------------------------------------------------------------------------

Helpers.expect = {}

local function to_range(from, to)
  return { from = from, to = to }
end

Helpers.expect.has_no_selection = MiniTest.new_expectation(
  'selection determination',
  function(actual)
    local mode = actual.api.nvim_get_mode().mode

    return mode ~= 'v' and mode ~= 'V'
  end,
  function()
    return 'Something is selected.'
  end
)

Helpers.expect.has_range = MiniTest.new_expectation(
  'selection range determination',
  function(expected, actual)
    local has_row = true
    local has_col = true

    if expected.r then
      has_row = vim.deep_equal(to_range(expected.r[1], expected.r[2]), actual.row)
    end

    if expected.c then
      has_col = vim.deep_equal(to_range(expected.c[1], expected.c[2]), actual.col)
    end

    return has_row and has_col
  end,
  function(expected, actual)
    return string.format(
      'expected: %s\nactual: %s', Helpers.to_string(expected), Helpers.to_string(actual)
    )
  end
)

-- / Inspection
-- -------------------------------------------------------------------------------------------------

function Helpers.dump(thing)
  Helpers.print('----------')
  Helpers.print(Helpers.to_string(thing))
  Helpers.print('----------')
end

function Helpers.print(thing)
  vim.notify(Helpers.to_string(thing))
end

function Helpers.to_string(thing)
  if type(thing) == 'table' then
    local joined = '{ '

    for k, v in pairs(thing) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      joined = joined .. '['.. k ..'] = ' .. Helpers.to_string(v) .. ','
    end

    return joined .. ' }'
  elseif thing == nil then
    return 'nil'
  else
    return tostring(thing)
  end
end

return Helpers
