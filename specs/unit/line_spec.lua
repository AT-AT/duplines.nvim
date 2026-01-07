package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq, no_error = MiniTest.expect.equality, MiniTest.expect.no_error
local has_no_selection = H.expect.has_no_selection
local child = H.new_child_neovim('duplines.Line')
local const = require('duplines.enum')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.Line', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('on_range()', function()

    describe('can create instance', function()

      it('with no options specified', function()
        -- Arrange
        local expected = child.config_of('options')

        -- Act
        local actual = child.lua_get([[SUT.on_range({})]])

        -- Assert
        eq(expected, actual.params)
      end)

      it('with empty options', function()
        -- Arrange
        local expected = child.config_of('options')

        -- Act
        local actual = child.lua_get([[SUT.on_range({}, {})]])

        -- Assert
        eq(expected, actual.params)
      end)

      it('with valid options that overwrite defaults', function()
        -- Arrange
        local expected = {
          target = const.TARGET.src,
          cursor = const.CURSOR_POS.keep,
          select = true,
        }
        local option_str = '{'
          .. 'target = "' .. const.TARGET.src .. '",'
          .. 'cursor = "' .. const.CURSOR_POS.keep .. '",'
          .. 'select = ' .. 'true'
          .. '}'

        -- Act
        local actual = child.lua_get('SUT.on_range({}, ' .. option_str .. ')')

        -- Assert
        eq(expected, actual.params)
      end)

    end)

  end)

  -- / Duplication
  -- -----------------------------------------------------------------------------------------------
  describe('[duplication]', function()

    -- NOTE:
    --  - Mocking dependent class "Range" is quite difficult, so we use the actual module.
    --  - Since there are many patterns and it is difficult to cover them all, use reasonable cases.
    local function prepare_line_instance_on_single_line_with_no_selection()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('foobarbazqux')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    local function prepare_line_instance_on_single_line_with_selection()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('foobarbazqux')
      child.type_keys('v4l')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    local function prepare_line_instance_on_multiple_lines()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('foobarbazqux1', '', 'foobarbazqux3')
      child.type_keys('4l<S-v>2j2h')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    local function prepare_line_instance_on_multiple_lines_with_inverted_range()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('foobarbazqux1', '', 'foobarbazqux3')
      child.type_keys('2j2l<S-v>2k2l')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    local function prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('', 'foobarbazqux', '')
      child.type_keys('<S-v>2j')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('duplicate()', function()

      describe('can duplicate', function()

        it('single line with no selection', function()
          -- Arrange
          prepare_line_instance_on_single_line_with_no_selection()

          -- Act
          child.lua([[L:duplicate()]])

          -- Assert
          eq(child.lines_on(0, 0), child.lines_on(1, 1))
        end)

        it('single line with selection', function()
          -- Arrange
          prepare_line_instance_on_single_line_with_selection()

          -- Act
          child.lua([[L:duplicate()]])

          -- Assert
          eq(child.lines_on(0, 0), child.lines_on(1, 1))
        end)

        it('multiple lines', function()
          -- Arrange
          prepare_line_instance_on_multiple_lines()

          -- Act
          child.lua([[L:duplicate()]])

          -- Assert
          eq(child.lines_on(0, 2), child.lines_on(3, 5))
        end)

        it('multiple lines with inverted range', function()
          -- Arrange
          prepare_line_instance_on_multiple_lines_with_inverted_range()

          -- Act
          child.lua([[L:duplicate()]])

          -- Assert
          eq(child.lines_on(0, 2), child.lines_on(3, 5))
        end)

        it('multiple lines surrounded by blank ones', function()
          -- Arrange
          prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

          -- Act
          child.lua([[L:duplicate()]])

          -- Assert
          eq(child.lines_on(0, 2), child.lines_on(3, 5))
        end)

        -- / Cursor Placement Target
        -- -----------------------------------------------------------------------------------------
        describe('on source', function()

          before_each(function()
            child.change_config('target = "' .. const.TARGET.src .. '"')
          end)

          -- / Selection
          -- ---------------------------------------------------------------------------------------
          describe('unselected after duplication', function()

            before_each(function()
              child.change_config('select = false')
            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with keeping cursor position', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.keep .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 4 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 2, 2 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 4 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 2, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on head of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.head .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on tail of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.tail .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 2, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 2, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 2, 0 }, child.cursor_pos())
              end)

            end)

          end)

          -- / Selection
          -- ---------------------------------------------------------------------------------------
          describe('selected after duplication', function()

            before_each(function()
              child.change_config('select = true')
            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with keeping cursor position', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.keep .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 4 } }, child.get_visual_pos())
                eq({ 0, 4 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 4 }, { 2, 2 } }, child.get_visual_pos())
                eq({ 2, 2 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 4 }, { 2, 2 } }, child.get_visual_pos())
                eq({ 0, 4 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 2, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on head of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.head .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on tail of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.tail .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 0, 0 } }, child.get_visual_pos())
                eq({ 0, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 2, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 2, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 0, 0 }, { 2, 0 } }, child.get_visual_pos())
                eq({ 2, 0 }, child.cursor_pos())
              end)

            end)

          end)

        end)

        -- / Cursor Placement Target
        -- -----------------------------------------------------------------------------------------
        describe('on destination', function()

          before_each(function()
            child.change_config('target = "' .. const.TARGET.dest .. '"')
          end)

          -- / Selection
          -- ---------------------------------------------------------------------------------------
          describe('unselected after duplication', function()

            before_each(function()
              child.change_config('select = false')
            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with keeping cursor position', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.keep .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 4 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 5, 2 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 3, 4 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 5, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on head of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.head .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 3, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 3, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 3, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on tail of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.tail .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 5, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 5, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                has_no_selection(child)
                eq({ 5, 0 }, child.cursor_pos())
              end)

            end)

          end)

          -- / Selection
          -- ---------------------------------------------------------------------------------------
          describe('selected after duplication', function()

            before_each(function()
              child.change_config('select = true')
            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with keeping cursor position', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.keep .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 0 } }, child.get_visual_pos())
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 4 } }, child.get_visual_pos())
                eq({ 1, 4 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 4 }, { 5, 2 } }, child.get_visual_pos())
                eq({ 5, 2 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 4 }, { 5, 2 } }, child.get_visual_pos())
                eq({ 3, 4 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 5, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on head of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.head .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 0 } }, child.get_visual_pos())
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 0 } }, child.get_visual_pos())
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 3, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 3, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 3, 0 }, child.cursor_pos())
              end)

            end)

            -- / Cursor Position
            -- -------------------------------------------------------------------------------------
            describe('with placing cursor on tail of source', function()

              before_each(function()
                child.change_config('cursor = "' .. const.CURSOR_POS.tail .. '"')
              end)

              it('single line with no selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_no_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 0 } }, child.get_visual_pos())
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('single line with selection', function()
                -- Arrange
                prepare_line_instance_on_single_line_with_selection()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 1, 0 }, { 1, 0 } }, child.get_visual_pos())
                eq({ 1, 0 }, child.cursor_pos())
              end)

              it('multiple lines, T ->(>) B', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 5, 0 }, child.cursor_pos())
              end)

              it('multiple lines, B ->(<) T', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_with_inverted_range()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 5, 0 }, child.cursor_pos())
              end)

              it('multiple lines surrounded by blank ones', function()
                -- Arrange
                prepare_line_instance_on_multiple_lines_surrounded_by_blank_ones()

                -- Act
                child.lua([[L:duplicate()]])

                -- Assert
                eq({ { 3, 0 }, { 5, 0 } }, child.get_visual_pos())
                eq({ 5, 0 }, child.cursor_pos())
              end)

            end)

          end)

        end)

      end)

    end)

  end)

  -- / Dynamic Configuration
  -- -----------------------------------------------------------------------------------------------
  describe('[dynamic configuration]', function()

    -- NOTE:
    --  - It is bad practice to make "params" public when they should be private, and then reference
    --    them for testing. However, we will allow it for the following reasons:
    --      - Implementing private, which is not in the language specification, would complicate the
    --        implementation, but this plugin does not need to go that far.
    --      - It would be better for tests in this group to reference the results of duplicate(),
    --        but we will use the current method for simplicity.

    local function prepare_line_instance()
      child.lua([[RM = require('duplines.Range')]])
      child.prepare_rows('foobarbazqux')
      child.lua([[R = RM.from_pos()]])
      child.lua([[L = SUT.on_range(R)]])
    end

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('src()', function()

      it('can change cursor placement target option and return self', function()
        -- Arrange
        child.change_config('target = "' .. const.TARGET.dest .. '"')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:src()]])

        -- Assert
        eq(const.TARGET.src, actual.params.target)
        no_error(function()
          child.lua([[L:src():src()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('dest()', function()

      it('can change cursor placement target option and return self', function()
        -- Arrange
        child.change_config('target = "' .. const.TARGET.src .. '"')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:dest()]])

        -- Assert
        eq(const.TARGET.dest, actual.params.target)
        no_error(function()
          child.lua([[L:dest():dest()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('keep()', function()

      it('can change cursor position option and return self', function()
        -- Arrange
        child.change_config('cursor = "' .. const.CURSOR_POS.head .. '"')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:keep()]])

        -- Assert
        eq(const.CURSOR_POS.keep, actual.params.cursor)
        no_error(function()
          child.lua([[L:keep():keep()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('head()', function()

      it('can change cursor position option and return self', function()
        -- Arrange
        child.change_config('cursor = "' .. const.CURSOR_POS.tail .. '"')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:head()]])

        -- Assert
        eq(const.CURSOR_POS.head, actual.params.cursor)
        no_error(function()
          child.lua([[L:head():head()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('tail()', function()

      it('can change cursor position option and return self', function()
        -- Arrange
        child.change_config('cursor = "' .. const.CURSOR_POS.keep .. '"')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:tail()]])

        -- Assert
        eq(const.CURSOR_POS.tail, actual.params.cursor)
        no_error(function()
          child.lua([[L:tail():tail()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('select()', function()

      it('can change selection after duplication option and return self', function()
        -- Arrange
        child.change_config('select = false')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:select()]])

        -- Assert
        eq(true, actual.params.select)
        no_error(function()
          child.lua([[L:select():select()]])
        end)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('deselect()', function()

      it('can change selection after duplication option and return self', function()
        -- Arrange
        child.change_config('select = true')
        prepare_line_instance()

        -- Act
        local actual = child.lua_get([[L:deselect()]])

        -- Assert
        eq(false, actual.params.select)
        no_error(function()
          child.lua([[L:deselect():deselect()]])
        end)
      end)

    end)

  end)

  -- / Multibyte Characters
  -- -----------------------------------------------------------------------------------------------
  describe('[multibyte characters]', function()

    it('can be processed in the same way', function()
      MiniTest.skip(
        'In the current implementation, all characters including multi-byte characters,'
        .. ' are processed as Byte representations, so no special tests are provided.'
      )
    end)

  end)

end)
