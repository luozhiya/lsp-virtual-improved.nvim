# lsp-virtual-improved

## 📦 Installation

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

## ⚙️ Configuration

### Setup

lsp-virtual-improved comes with the following defaults:

```lua
virtual_improved = {
  severity = nil, -- Same usage as virtual_text.severity
  spacing = 4, -- Same usage as virtual_text.spacing
  prefix = '●', -- Same usage as virtual_text.prefix
  suffix = '', -- Same usage as virtual_text.suffix
  current_line = 'default', -- Current Line: 'only', 'hide', 'default'
  code = nil, -- Show diagnostic code.
},
```

Default different from virtual_text:
- **prefix:** Change the prefix icon '■' -> '●'

Current Line:
- **only:** Show current line only when `CursorMoved` event triggered
- **hide:** Hide current line when `CursorMoved` event triggered
- **default:** Show all lines

> 💡 if you want to show only current line, you can use the settings below

```lua
local diagnostics = {
  virtual_text = false, -- Disable builtin virtual text diagnostic.
  virtual_improved = {
    current_line = 'only',
  },
}
vim.diagnostic.config(diagnostics)
```

### Disable lsp-virtual-improved
```lua
virtual_improved = false
```

## 🎉 Special Thanks
- https://todo.sr.ht/~whynothugo/lsp_lines.nvim
- neovim/runtime/lua/vim/diagnostic.lua
- https://github.com/folke/trouble.nvim
