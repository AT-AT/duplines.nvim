# Duplines.nvim

Duplicate one or more lines. That's all.

![Sample](sample.png)

## Acknowledgements

Wrote this plugin with **a lot of** hints and motivations from [duplicate.nvim](https://github.com/hinell/duplicate.nvim).  
Thanks.

## Features

- Duplicate the line with the cursor in normal mode.
- Duplicate the selected lines in V-LINE mode.
- Enable to specify the cursor position after duplication.
- Enable to make the duplicated range selected after duplication.

## Requirements

- Neovim >= 0.9.5
  - Because it was developed with this version. Since it is simple, I think it will work even in lower versions.

## Installation

Install the plugin with your preferred package manager. Here is an example in [lazy.nvim](https://github.com/folke/lazy.nvim).  
```lua
{
  'AT-AT/duplines.nvim',
  config = function()
    -- No need to execute unless you want to change the default option values.
    require('duplines').setup({
      -- options...
    })
  end,
}
```

## Configuration

Below are the configurable options and their default values.
```lua
{
  -- The "range" here refers to the line-wise block of the source or destination.

  -- The range to place the cursor on or select after duplication.
  -- See documentation for available values and details.
  target = 'dest',

  -- The position within the range to place the cursor after duplication.
  -- See documentation for available values and details.
  cursor = 'head',

  -- Whether the range should be selected or not after duplication.
  select = false,
}
```

See [the documentation](doc/duplines-nvim.txt) for details.

## Key Mappings

This plugin does not provide a default keymap. Below is an example.
```lua
-- The options and behavior may be different from your intuition.
-- Please refer to the documentation for details.

-- Duplicate upwards, place the cursor on the first row of the destination range,
-- and do not select the destination range.
vim.keymap.set({ 'n', 'x' }, '<M-UP>', function()
  -- Options can be specified as arguments for API.line().
  require('duplines').line({ target = 'src', cursor = 'head', select = false }):duplicate()
end)

-- Duplicate downwards, place the cursor on the first row of the destination range,
-- and do not select the destination range.
vim.keymap.set({ 'n', 'x' }, '<M-DOWN>', function()
  -- Options can also be specified in configuration methods.
  require('duplines').line():dest():head():deselect():duplicate()
end)
```

If you are using Lazy.nvim, you can perform lazy loading at the same time by registering with the "keys" option.
```lua
{
  keys = {
    {
      '<M-Up>',
      function()
        require('duplines').line():src():head():deselect():duplicate()
      end,
      mode = { 'n', 'x' },
    },
    {
      '<M-Down>',
      function()
        require('duplines').line():dest():head():deselect():duplicate()
      end,
      mode = { 'n', 'x' },
    },
  },
}
```

## Related Plugins

- [duplicate.nvim](https://github.com/hinell/duplicate.nvim).

## License

[MIT](LICENSE)

