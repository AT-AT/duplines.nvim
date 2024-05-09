local helper = require('spec.helpers')
local assert = helper.assert
local lines_on = helper.lines_on
local prepare_rows = helper.prepare_rows

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('API.line() can create instance which duplicates lines', function()
  local sut_module
  local sut

  before_each(function()
    helper.cleanup_modules('duplines')
    sut_module = require('duplines')
    sut_module.setup()
    sut = sut_module.line
    prepare_rows()
  end)

  after_each(function()
    helper.cleanup()
  end)

  it('with options from argument', function ()
    -- Act
    sut({ target = 'dest', cursor = 'head', select = false }):duplicate()

    -- Assert
    assert.same(lines_on(0, 0), lines_on(1, 1))
  end)

  it('with options by wrapper methods', function ()
    -- Act
    sut():dest():head():deselect():duplicate()

    -- Assert
    assert.same(lines_on(0, 0), lines_on(1, 1))
  end)
end)
