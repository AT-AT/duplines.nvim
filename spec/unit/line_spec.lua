local helper = require('spec.helpers')
local assert = helper.assert
local cursor_pos = helper.cursor_pos
local lines_on = helper.lines_on
local prepare_rows = helper.prepare_rows
local select_end_pos = helper.select_end_pos
local select_start_pos = helper.select_start_pos
local start_vline = helper.vline_keycode
local mock_config_option = helper.mock_config_option
local to_range_index = helper.to_range_index

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('Line class', function()
  local sut_class
  local sut_factory
  local sut
  local const

  before_each(function()
    helper.cleanup_modules('duplines')
    sut_class = require('duplines.Line')
    sut_factory = sut_class.on_range
    const = require('duplines.enum')
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Class Method
  -- -----------------------------------------------------------------------------------------------
  describe('class method', function ()

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('on_range() (factory) can create instance', function ()
      before_each(function()
        sut = sut_factory

        mock_config_option({ target = 'foo', cursor = 'bar', select = 'baz' })
      end)

      it('with falsy parameters', function ()
        -- Arrange
        local expected = { target = 'foo', cursor = 'bar', select = 'baz' }

        -- Act
        local actual = sut({})

        -- Assert
        assert.same(expected, actual.params)

        -- Act
        actual = sut({}, {})

        -- Assert
        assert.same(expected, actual.params)
      end)

      it('with valid parameters that overwrite defaults', function ()
        -- Arrange
        local expected = {
          target = const.TARGET.src,
          cursor = const.CURSOR_POS.keep,
          select = true,
        }

        -- Act
        local actual = sut({}, expected)

        -- Assert
        assert.same(expected, actual.params)
      end)
    end) -- Function
  end) -- Class Method

  -- / Instance Method
  -- -----------------------------------------------------------------------------------------------
  describe('instance method', function ()

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('duplicate() can duplicate', function ()
      local params

      -- NOTE: It is TOO difficult to mock dependent class "Range", so use a real module.
      local function create_range(from, to, invert)
        local range = require('duplines.Range')

        range.col = to_range_index(from[2], to[2])
        range.row = to_range_index(from[1], to[1])
        range.inverted = invert

        return range
      end

      -- NOTE: Since there are many patterns and it is difficult to cover them all, use four
      --       reasonable cases.
      -- NOTE: It is not possible to emulate/get the col value of marks "m<" and ">m" in a test at
      --       this time.

      -- (0,0) -> (0,4) or (0,0)
      local function prepare_instance_on_single_line(kind)
        kind = vim.tbl_deep_extend('force', { normal = false }, kind or {})

        prepare_rows('foobarbazqux')

        if not kind.normal then
          vim.api.nvim_feedkeys('v4l' .. start_vline, 'x', false)
        end

        local range = kind.normal
          and create_range({ 0, 0 }, { 0, 0 }, false)
          or create_range({ 0, 0 }, { 0, 4 }, false)

        return sut_factory(range, params)
      end

      -- (0,4) <--> (2,2)
      local function prepare_instance_on_multiple_lines(kind)
        kind = vim.tbl_deep_extend('force', { invert = false }, kind or {})

        prepare_rows('foobarbazqux1', '', 'foobarbazqux3')

        if kind.invert then
          vim.api.nvim_feedkeys('2j2l' .. start_vline .. '2k2l', 'x', false)
        else
          vim.api.nvim_feedkeys('4l' .. start_vline .. '2j2h', 'x', false)
        end

        local range = create_range({ 0, 4 }, { 2, 2 }, kind.invert)

        return sut_factory(range, params)
      end

      local function prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

        prepare_rows('', 'foobarbazqux', '')

        vim.api.nvim_feedkeys(start_vline .. '2j', 'x', false)

        local range = create_range({ 0, 0 }, { 2, 0 }, false)

        return sut_factory(range, params)
      end

      before_each(function()
        sut = sut_class.duplicate

        -- Always overwrite default options.
        params = {
          cursor = const.CURSOR_POS.keep,
          select = false,
          target = const.TARGET.dest,
        }
      end)

      -- / Duplication
      -- -------------------------------------------------------------------------------------------
      it('with single line on normal mode', function ()
        -- Arrange
        local line = prepare_instance_on_single_line({ normal = true })

        -- Act
        sut(line)

        -- Assert
        assert.same(lines_on(0, 0), lines_on(1, 1))
      end)

      it('with single line', function ()
        -- Arrange
        local line = prepare_instance_on_single_line()

        -- Act
        sut(line)

        -- Assert
        assert.same(lines_on(0, 0), lines_on(1, 1))
      end)

      it('with multiple lines', function ()
        -- Arrange
        local line = prepare_instance_on_multiple_lines()

        -- Act
        sut(line)

        -- Assert
        assert.same(lines_on(0, 2), lines_on(3, 5))
      end)

      it('with lines surrounded by blank ones', function ()
        -- Arrange
        local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

        -- Act
        sut(line)

        -- Assert
        assert.same(lines_on(0, 2), lines_on(3, 5))
      end)

      -- / Target
      -- -------------------------------------------------------------------------------------------
      describe('on source', function ()
        before_each(function ()
          params.target = const.TARGET.src
        end)

        -- / Cursor Placement
        -- -----------------------------------------------------------------------------------------
        describe('with placing cursor without selection', function ()
          before_each(function ()
            params.select = false
          end)

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with keeping cursor position', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.keep
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos()) -- In normal mode, both row and col can be
              assert.same({ -1, -1 }, select_end_pos())   -- tested correctly (Same below).
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 1, 0 }) -- In V-LINE mode, col cannot be obtained
              assert.is_vline_end_row({ 1, 4 })   -- correctly, so only row is tested (Same below).
              assert.same({ 0, 4 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 })
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 2, 2 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 0, 4 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on head of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.head
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos())
              assert.same({ -1, -1 }, select_end_pos())
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 1, 0 })
              assert.is_vline_end_row({ 1, 4 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 })
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on tail of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.tail
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos())
              assert.same({ -1, -1 }, select_end_pos())
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 1, 0 })
              assert.is_vline_end_row({ 1, 4 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 })
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 2, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 2, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)
          end) -- Cursor Position
        end) -- Cursor Placement

        -- / Selection
        -- -----------------------------------------------------------------------------------------
        describe('with selection', function ()
          before_each(function ()
            params.select = true
          end)

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with keeping cursor position', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.keep
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 0, 0 }, select_start_pos())
              assert.same({ 0, 0 }, select_end_pos())
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 4 })
              assert.same({ 0, 4 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 4 })
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 2, 2 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 0, 4 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on head of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.head
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 0, 0 }, select_start_pos())
              assert.same({ 0, 0 }, select_end_pos())
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on tail of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.tail
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 0, 0 }, select_start_pos())
              assert.same({ 0, 0 }, select_end_pos())
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 0 })
              assert.same({ 0, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 2, 0 }, cursor_pos())
            end)
          end) -- Cursor Position
        end) -- Selection
      end) -- Target

      -- / Target
      -- -------------------------------------------------------------------------------------------
      describe('on destination', function ()
        before_each(function ()
          params.target = const.TARGET.dest
        end)

        -- / Cursor Placement
        -- -----------------------------------------------------------------------------------------
        describe('with placing cursor without selection', function ()
          before_each(function ()
            params.select = false
          end)

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with keeping cursor position', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.keep
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos())
              assert.same({ -1, -1 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 4 })
              assert.same({ 1, 4 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 })
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 5, 2 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 3, 4 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on head of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.head
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos())
              assert.same({ -1, -1 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 4 })
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 })
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 3, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 3, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 3, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on tail of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.tail
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.same({ -1, -1 }, select_start_pos())
              assert.same({ -1, -1 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 0, 4 })
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 })
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 5, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 2, 2 })
              assert.same({ 5, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode_not()
              assert.is_vline_start_row({ 0, 0 })
              assert.is_vline_end_row({ 2, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)
          end) -- Cursor Position
        end) -- Cursor Placement

        -- / Selection
        -- -----------------------------------------------------------------------------------------
        describe('with selection', function ()
          before_each(function ()
            params.select = true
          end)

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with keeping cursor position', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.keep
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 1, 0 }, select_start_pos())
              assert.same({ 1, 0 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 1, 0 })
              assert.is_vline_end_row({ 1, 4 })
              assert.same({ 1, 4 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 4 })
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 5, 2 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 4 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 2 })
              assert.same({ 3, 4 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on head of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.head
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 1, 0 }, select_start_pos())
              assert.same({ 1, 0 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 1, 0 })
              assert.is_vline_end_row({ 1, 0 })
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 3, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 3, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 3, 0 }, cursor_pos())
            end)
          end) -- Cursor Position

          -- / Cursor Position
          -- ---------------------------------------------------------------------------------------
          describe('with placing cursor on tail of source', function ()
            before_each(function ()
              params.cursor = const.CURSOR_POS.tail
            end)

            it('with single line on normal mode', function ()
              -- Arrange
              local line = prepare_instance_on_single_line({ normal = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.same({ 1, 0 }, select_start_pos())
              assert.same({ 1, 0 }, select_end_pos())
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with single line', function ()
              -- Arrange
              local line = prepare_instance_on_single_line()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 1, 0 })
              assert.is_vline_end_row({ 1, 0 })
              assert.same({ 1, 0 }, cursor_pos())
            end)

            it('with multiple lines, T ->(>) B', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)

            it('with multiple lines, B ->(<) T', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines({ invert = true })

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 }) -- start/end marks are ordered by Vim.
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)

            it('with lines surrounded by blank ones', function ()
              -- Arrange
              local line = prepare_instance_on_multiple_lines_surrounded_by_blank_ones()

              -- Act
              sut(line)

              -- Assert
              assert.is_vline_mode()
              assert.is_vline_start_row({ 3, 0 })
              assert.is_vline_end_row({ 5, 0 })
              assert.same({ 5, 0 }, cursor_pos())
            end)
          end) -- Cursor Position
        end) -- Selection
      end) -- Target
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('parameter wrapper method', function ()
      local instance

      before_each(function()
        instance = sut_factory({}, { to = 'foo', cursor = 'bar', select = 'baz' })
      end)

      it('src() can change direction parameter', function ()
        -- Arrange
        sut = sut_class.src

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.equals(const.TARGET.src, instance.params.target)
        assert.equals(instance, actual)
      end)

      it('dest() can change direction parameter', function ()
        -- Arrange
        sut = sut_class.dest

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.equals(const.TARGET.dest, instance.params.target)
        assert.equals(instance, actual)
      end)

      it('keep() can change cursor position parameter', function ()
        -- Arrange
        sut = sut_class.keep

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.equals(const.CURSOR_POS.keep, instance.params.cursor)
        assert.equals(instance, actual)
      end)

      it('head() can change cursor position parameter', function ()
        -- Arrange
        sut = sut_class.head

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.equals(const.CURSOR_POS.head, instance.params.cursor)
        assert.equals(instance, actual)
      end)

      it('tail() can change cursor position parameter', function ()
        -- Arrange
        sut = sut_class.tail

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.equals(const.CURSOR_POS.tail, instance.params.cursor)
        assert.equals(instance, actual)
      end)

      it('select() can change selection parameter', function ()
        -- Arrange
        sut = sut_class.select

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.is_true(instance.params.select)
        assert.equals(instance, actual)
      end)

      it('deselect() can change selection parameter', function ()
        -- Arrange
        sut = sut_class.deselect

        -- Act
        local actual = sut(instance)

        -- Assert
        assert.is_false(instance.params.select)
        assert.equals(instance, actual)
      end)
    end) -- Function
  end) -- Instance Method
end)
