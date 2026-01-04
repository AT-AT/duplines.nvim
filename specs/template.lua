package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq, ne = MiniTest.expect.equality, MiniTest.expect.no_equality
local error, no_error = MiniTest.expect.error, MiniTest.expect.no_error
local has_no_selection, has_range = H.expect.has_no_selection, H.expect.has_range
local child = H.new_child_neovim('duplines.XXXXX')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.XXXXX', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('XXXXX()', function()

    describe('-----XXXXX-----', function()

      it('-----XXXXX-----', function()
        -- Arrange

        -- Act

        -- Assert
      end)

    end)

  end)

end)
