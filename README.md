# lsp-virtual-improved

## Installation

For example with lazy.nvim:

```lua
{
  'luozhiya/lsp-virtual-improved.nvim'
  event = { 'LspAttach' },
  config = function()
    require('lsp-virtual-improved').setup()
  end,
}
```

## Config
```lua
local diagnostics = {
  virtual_text = false, -- Disable builtin virtual text diagnostic.
  virtual_improved = {
    -- virtual_text options
    -- severity = { min = vim.diagnostic.severity.ERROR, max = vim.diagnostic.severity.ERROR },
    -- severity_limit = 'Error',
    -- spacing = 4,
    -- prefix = '●',
    -- Extend options
    current_line = 'default', -- 'only' current line, 'hide' current line, 'default' show all lines.
    code = false, -- Show diagnostic code.
  },
}
vim.diagnostic.config(diagnostics)
```

## Special Thanks
- https://todo.sr.ht/~whynothugo/lsp_lines.nvim
- neovim/runtime/lua/vim/diagnostic.lua
