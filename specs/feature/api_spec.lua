package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local has_no_selection = H.expect.has_no_selection
local child = H.new_child_neovim('duplines')
local const = require('duplines.enum')

-- / API
-- -------------------------------------------------------------------------------------------------
describe('API', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('setup()', function()

    describe('can configure options', function()

      before_each(function()
        child.lua('SUT.setup({'
          .. 'target = "' .. const.TARGET.src .. '",'
          .. 'select = false,'
          .. 'cursor = "' .. const.CURSOR_POS.keep .. '",'
          .. '})')
      end)

      -- / Subject
      -- -------------------------------------------------------------------------------------------
      describe('line()', function()

        before_each(function()
          child.prepare_rows('foobarbazqux1', 'foobarbazqux2', 'foobarbazqux3')
          child.type_keys('2l<S-v>2j2l')
        end)

        describe('can duplicate lines', function()

          it('with configured options', function()
            -- Arrange

            -- Act
            child.lua([[SUT.line():duplicate()]])

            -- Assert
            eq(child.lines_on(0, 2), child.lines_on(3, 5))
            has_no_selection(child)
            eq({ 2, 4 }, child.cursor_pos())
          end)

          it('with passed options', function()
            -- Arrange
            local option_str = '{'
              .. 'target = "' .. const.TARGET.dest .. '",'
              .. 'cursor = "' .. const.CURSOR_POS.head .. '",'
              .. 'select = ' .. 'true'
              .. '}'

            -- Act
            child.lua('SUT.line(' .. option_str .. '):duplicate()')

            -- Assert
            eq(child.lines_on(0, 2), child.lines_on(3, 5))
            eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
            eq({ 3, 0 }, child.cursor_pos())
          end)

          it('with options by methods', function()
            -- Arrange

            -- Act
            child.lua([[SUT.line():dest():head():select():duplicate()]])

            -- Assert
            eq(child.lines_on(0, 2), child.lines_on(3, 5))
            eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
            eq({ 3, 0 }, child.cursor_pos())
          end)

        end)

      end)

    end)

  end)

end)
