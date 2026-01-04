package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local has_range = H.expect.has_range
local child = H.new_child_neovim('duplines.Range')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.Range', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Pre-Configuration
  -- -----------------------------------------------------------------------------------------------
  describe('(on stage)', function()

    before_each(function()
      child.prepare_rows('foo', 'bar', 'baz')
    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('from_pos()', function()

      describe('can create instance', function()

        -- / Row Number
        -- -----------------------------------------------------------------------------------------
        describe('with multiple rows selected', function()

          it('from top-left to bottom-right', function()
            -- Arrange
            child.type_keys('<S-v>jjll')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 0, 2 } }, actual)
            eq(false, actual.inverted)
          end)

          it('from top to bottom (same col)', function()
            -- Arrange
            child.type_keys('l<S-v>jj')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 1, 1 } }, actual)
            eq(false, actual.inverted)
          end)

          it('from top-right to bottom-left', function()
            -- Arrange
            child.type_keys('ll<S-v>jjhh')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 2, 0 } }, actual)
            eq(false, actual.inverted)
          end)

          it('from bottom-left to top-right', function()
            -- Arrange
            child.type_keys('jj<S-v>kkll')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 2, 0 } }, actual)
            eq(true, actual.inverted)
          end)

          it('from bottom to top (same col)', function()
            -- Arrange
            child.type_keys('jjl<S-v>kk')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 1, 1 } }, actual)
            eq(true, actual.inverted)
          end)

          it('from bottom-right to top-left', function()
            -- Arrange
            child.type_keys('jjll<S-v>kkhh')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 2 }, c = { 0, 2 } }, actual)
            eq(true, actual.inverted)
          end)

        end)

        -- / Row Number
        -- -----------------------------------------------------------------------------------------
        describe('with single row selected', function()

          it('in V-LINE mode', function()
            -- Arrange
            child.type_keys('l<S-v>')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 0, 0 }, c = { 1, 1 } }, actual)
            eq(false, actual.inverted)
          end)

          it('in normal mode', function()
            -- Arrange
            child.type_keys('j')

            -- Act
            local actual = child.lua_get([[SUT.from_pos()]])

            -- Assert
            has_range({ r = { 1, 1 }, c = { 0, 0 } }, actual)
            eq(false, actual.inverted)
          end)

        end)

      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('col_index()', function()

      it('can extract col index', function()
        -- Arrange
        child.type_keys('l<S-v>jl')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:col_index()]])

        -- Assert
        eq({ 1, 2 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('is_inverted()', function()

      it('can get state whether positions in range is inverted or not', function()
        -- Arrange
        child.type_keys('j<S-v>k')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:is_inverted()]])

        -- Assert
        eq(true, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_begin()', function()

      it('can extract position where selection actually started', function()
        -- Arrange
        child.type_keys('jjll<S-v>kkhh')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:pos_on_begin()]])

        -- Assert
        eq({ 2, 2 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_end()', function()

      it('can extract position where selection actually finished', function()
        -- Arrange
        child.type_keys('jjll<S-v>kkhh')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:pos_on_end()]])

        -- Assert
        eq({ 0, 0 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_head()', function()

      it('can extract position on head point', function()
        -- Arrange
        child.type_keys('ll<S-v>jj')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:pos_on_head()]])

        -- Assert
        eq({ 0, 0 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('pos_on_tail()', function()

      it('can extract position on tail point', function()
        -- Arrange
        child.type_keys('jjll<S-v>kkhh')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:pos_on_tail()]])

        -- Assert
        eq({ 2, 0 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('row_count()', function()

      it('can count row number in range', function()
        -- Arrange
        child.type_keys('<S-v>jj')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:row_count()]])

        -- Assert
        eq(3, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('row_index()', function()

      it('can extract row index', function()
        -- Arrange
        child.type_keys('<S-v>jj')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:row_index()]])

        -- Assert
        eq({ 0, 2 }, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('to_key_sequence()', function()

      describe('can generate key sequence between passed two positions', function()

        -- / Row Number
        -- -----------------------------------------------------------------------------------------
        describe('on single line', function()

          it('0 -> 0', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 0 }, { 0, 0 })]])

            -- Assert
            eq('', actual)
          end)

          it('L -> R', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 0 }, { 0, 4 })]])

            -- Assert
            eq('4l', actual)
          end)

          it('R -> L', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 4 }, { 0, 0 })]])

            -- Assert
            eq('4h', actual)
          end)

        end)

        -- / Row Number
        -- -----------------------------------------------------------------------------------------
        describe('on multiple lines', function()

          it('T -> B, 0 -> 0', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 0 }, { 4, 0 })]])

            -- Assert
            eq('4j', actual)
          end)

          it('B -> T, 0 -> 0', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 0 }, { 0, 0 })]])

            -- Assert
            eq('4k', actual)
          end)

          it('T -> B, 0 -> N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 0 }, { 4, 4 })]])

            -- Assert
            eq('4j4l', actual)
          end)

          it('B -> T, 0 -> N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 0 }, { 0, 4 })]])

            -- Assert
            eq('4k4l', actual)
          end)

          it('T -> B, N -> 0', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 4 }, { 4, 0 })]])

            -- Assert
            eq('4h4j', actual)
          end)

          it('B -> T, N -> 0', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 4 }, { 0, 0 })]])

            -- Assert
            eq('4h4k', actual)
          end)

          it('T -> B, N -> N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 2 }, { 4, 2 })]])

            -- Assert
            eq('4j', actual)
          end)

          it('B -> T, N -> N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 2 }, { 0, 2 })]])

            -- Assert
            eq('4k', actual)
          end)

          it('T -> B, M ->(<) N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 2 }, { 4, 4 })]])

            -- Assert
            eq('4j2l', actual)
          end)

          it('B -> T, M ->(<) N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 2 }, { 0, 4 })]])

            -- Assert
            eq('4k2l', actual)
          end)

          it('T -> B, M ->(>) N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 0, 4 }, { 4, 2 })]])

            -- Assert
            eq('4h4j2l', actual)
          end)

          it('B -> T, M ->(>) N', function()
            -- Arrange
            child.lua([[R = SUT.from_pos()]])

            -- Act
            local actual = child.lua_get([[R:to_key_sequence({ 4, 4 }, { 0, 2 })]])

            -- Assert
            eq('4h4k2l', actual)
          end)

        end)

      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('to_next()', function()

      it('can create new instance with state of copy destination', function()
        -- Arrange
        child.type_keys('l<S-v>jjl')
        child.lua([[R = SUT.from_pos()]])

        -- Act
        local actual = child.lua_get([[R:to_next()]])

        -- Assert
        has_range({ r = { 3, 5 }, c = { 1, 2 } }, actual)
      end)

    end)

  end)

end)
