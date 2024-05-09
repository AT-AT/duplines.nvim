local helper = require('spec.helpers')
local assert = helper.assert
local cursor_to = helper.cursor_to
local prepare_rows = helper.prepare_rows
local start_vline = helper.vline_keycode
local to_range_index = helper.to_range_index
local wait_for = helper.wait_for

-- / Subject
-- -------------------------------------------------------------------------------------------------
describe('Range class', function()
  local sut_class
  local sut_factory
  local sut

  before_each(function()
    helper.cleanup_modules('duplines')
    sut_class = require('duplines.Range')
    sut_factory = sut_class.from_pos
  end)

  after_each(function()
    helper.cleanup()
  end)

  -- / Class Method
  -- -----------------------------------------------------------------------------------------------
  describe('class method', function ()

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('from_pos() (factory) can create instance', function ()
      before_each(function()
        sut = sut_factory
      end)

      -- / Row Amount
      -- -------------------------------------------------------------------------------------------
      describe('with info of multiple rows selected in order', function ()
        it('from top-left to bottom-right', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys(start_vline .. 'jjll', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(0, 2), actual.col)
            assert.is_false(actual.inverted)
          end)
        end)

        it('from top to bottom on same col', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('l' .. start_vline .. 'jj', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(1, 1), actual.col)
            assert.is_false(actual.inverted)
          end)
        end)

        it('from top-right to bottom-left', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('ll' .. start_vline .. 'jjhh', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(2, 0), actual.col)
            assert.is_false(actual.inverted)
          end)
        end)

        it('from bottom-left to top-right', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('jj' .. start_vline .. 'kkll', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(2, 0), actual.col)
            assert.is_true(actual.inverted)
          end)
        end)

        it('from bottom to top on same col', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('jjl' .. start_vline .. 'kk', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(1, 1), actual.col)
            assert.is_true(actual.inverted)
          end)
        end)

        it('from bottom-right to top-left', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('jjll' .. start_vline .. 'kkhh', 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 2), actual.row)
            assert.same(to_range_index(0, 2), actual.col)
            assert.is_true(actual.inverted)
          end)
        end)
      end) -- Row Amount

      -- / Row Amount
      -- -------------------------------------------------------------------------------------------
      describe('with info of single row selected', function ()
        it('in V-LINE mode', function ()
          wait_for(function ()
            -- Arrange
            prepare_rows()
            vim.api.nvim_feedkeys('l' .. start_vline, 'x', false)
          end, function ()
            -- Assert
            assert.is_vline_mode()

            -- Act
            local actual = sut()

            -- Assert
            assert.same(to_range_index(0, 0), actual.row)
            assert.same(to_range_index(1, 1), actual.col)
            assert.is_false(actual.inverted)
          end)
        end)

        it('in normal mode', function ()
          -- Arrange
          prepare_rows()
          cursor_to(1, 0)

          -- Assert
          assert.is_vline_mode_not()

          -- Act
          local actual = sut()

          -- Assert
          assert.same(to_range_index(1, 1), actual.row)
          assert.same(to_range_index(0, 0), actual.col)
          assert.is_false(actual.inverted)
        end)
      end) -- Row Amount
    end) -- Function
  end) -- Class Method

  -- / Instance Method
  -- -----------------------------------------------------------------------------------------------
  describe('instance method', function ()
    local sut_instance

    before_each(function()
      sut_instance = sut_factory()
    end)

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('col_index()', function ()
      before_each(function()
        sut = sut_class.col_index
      end)

      it('can extract col indexes', function ()
        -- Arrange
        sut_instance.col = to_range_index(1, 2)

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 1, 2 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('is_inverted()', function ()
      before_each(function()
        sut = sut_class.is_inverted
      end)

      it('can get state whether positions in range is inverted or not', function ()
        -- Arrange
        sut_instance.inverted = true

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.is_true(actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_begin()', function ()
      before_each(function()
        sut = sut_class.pos_on_begin
      end)

      it('can extract position where selection actually started', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)
        sut_instance.col = to_range_index(1, 3)
        sut_instance.inverted = true

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 2, 3 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_end()', function ()
      before_each(function()
        sut = sut_class.pos_on_end
      end)

      it('can extract position where selection actually finished', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)
        sut_instance.col = to_range_index(1, 3)
        sut_instance.inverted = true

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 0, 1 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_head()', function ()
      before_each(function()
        sut = sut_class.pos_on_head
      end)

      it('can extract position on head point', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)
        sut_instance.col = to_range_index(1, 1)

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 0, 0 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_tail()', function ()
      before_each(function()
        sut = sut_class.pos_on_tail
      end)

      it('can extract position on tail point', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)
        sut_instance.col = to_range_index(1, 1)

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 2, 0 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('row_count()', function ()
      before_each(function()
        sut = sut_class.row_count
      end)

      it('can count row number in range', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same(3, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('row_index()', function ()
      before_each(function()
        sut = sut_class.row_index
      end)

      it('can extract row indexes', function ()
        -- Arrange
        sut_instance.row = to_range_index(1, 2)

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same({ 1, 2 }, actual)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('to_key_sequence() can generate key sequence between passed two positions', function ()
      before_each(function()
        sut = sut_class.to_key_sequence
      end)

      describe('on single line', function ()
        it('0 -> 0', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 0 }, { 0, 0 })

          -- Assert
          assert.equals('', actual)
        end)

        it('L -> R', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 0 }, { 0, 4 })

          -- Assert
          assert.equals('4l', actual)
        end)

        it('R -> L', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 4 }, { 0, 0 })

          -- Assert
          assert.equals('4h', actual)
        end)
      end)

      describe('on multiple lines', function ()
        it('T -> B, 0 -> 0', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 0 }, { 4, 0 })

          -- Assert
          assert.equals('4j', actual)
        end)
        it('B -> T, 0 -> 0', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 0 }, { 0, 0 })

          -- Assert
          assert.equals('4k', actual)
        end)

        it('T -> B, N -> 0', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 4 }, { 4, 0 })

          -- Assert
          assert.equals('4h4j', actual)
        end)

        it('B -> T, N -> 0', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 4 }, { 0, 0 })

          -- Assert
          assert.equals('4h4k', actual)
        end)

        it('T -> B, 0 -> N', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 0 }, { 4, 4 })

          -- Assert
          assert.equals('4j4l', actual)
        end)

        it('B -> T, 0 -> N', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 0 }, { 0, 4 })

          -- Assert
          assert.equals('4k4l', actual)
        end)

        it('T -> B, N -> N', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 2 }, { 4, 2 })

          -- Assert
          assert.equals('4j', actual)
        end)

        it('B -> T, N -> N', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 2 }, { 0, 2 })

          -- Assert
          assert.equals('4k', actual)
        end)

        it('T -> B, M ->(<) N', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 2 }, { 4, 4 })

          -- Assert
          assert.equals('4j2l', actual)
        end)

        it('B -> T, M ->(<) N', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 2 }, { 0, 4 })

          -- Assert
          assert.equals('4k2l', actual)
        end)

        it('T -> B, M ->(>) N', function ()
          -- Act
          local actual = sut(sut_instance, { 0, 4 }, { 4, 2 })

          -- Assert
          assert.equals('4h4j2l', actual)
        end)

        it('B -> T, M ->(>) N', function ()
          -- Act
          local actual = sut(sut_instance, { 4, 4 }, { 0, 2 })

          -- Assert
          assert.equals('4h4k2l', actual)
        end)
      end)
    end) -- Function

    -- / Function
    -- ---------------------------------------------------------------------------------------------
    describe('to_next()', function ()
      before_each(function()
        sut = sut_class.to_next
      end)

      it('can create new instance with state of copy destination', function ()
        -- Arrange
        sut_instance.row = to_range_index(0, 2)
        sut_instance.col = to_range_index(1, 2)
        sut_instance.inverted = false

        -- Act
        local actual = sut(sut_instance)

        -- Assert
        assert.same(to_range_index(3, 5), actual.row)
        assert.same(to_range_index(1, 2), actual.col)
        assert.is_false(actual.inverted)
      end)
    end) -- Function
  end) -- Instance Method
end)
