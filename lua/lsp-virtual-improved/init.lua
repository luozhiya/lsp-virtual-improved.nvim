local M = {}

local render = require('lsp-virtual-improved.render')

local function filter_current_line(diagnostics, ns, bufnr, opts)
  local show_diag = {}
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, diagnostic in pairs(diagnostics) do
    local condition = diagnostic.end_lnum and (lnum >= diagnostic.lnum and lnum <= diagnostic.end_lnum)
      or (lnum == diagnostic.lnum)
    if
      (opts.virtual_improved.current_line == 'hide' and not condition)
      or (opts.virtual_improved.current_line == 'only' and condition)
    then
      table.insert(show_diag, diagnostic)
    end
  end
  render.show(ns, bufnr, show_diag, opts)
end

---@class Opts
---@field virtual_improved OptsVirtualImproved Options for lsp-virtual-improved plugin

---@class OptsVirtualImproved
---@field severity table|nil
---@field source boolean|string|nil
---@field spacing number|nil
---@field prefix string|function|nil
---@field suffix string|function|nil
---@field format function|nil
---@field current_line string|nil Render for current line

-- Registers a wrapper-handler to render lsp virtual text.
-- This should usually only be called once, during initialisation.
M.setup = function()
  local _augroup = function(name)
    return vim.api.nvim_create_augroup('LspVirtualImproved_' .. name, { clear = true })
  end
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = _augroup('update_diagnostic_cache'),
    pattern = '*',
    callback = function(args)
      render.diagnostic_cache = args.data.diagnostics
    end,
    desc = 'Update Diagnostic Cache',
  })
  vim.diagnostic.handlers.virtual_improved = {
    ---@param namespace number
    ---@param bufnr number
    ---@param diagnostics table
    ---@param opts boolean|Opts
    show = function(namespace, bufnr, diagnostics, opts)
      local ns = vim.diagnostic.get_namespace(namespace)
      if not ns.user_data.virt_improved_ns then
        ns.user_data.virt_improved_ns = vim.api.nvim_create_namespace('')
      end
      opts = opts or {}
      if opts.virtual_improved then
        opts.virtual_improved.current_line = opts.virtual_improved.current_line or 'default'
        if vim.tbl_contains({ 'only', 'hide' }, opts.virtual_improved.current_line) then
          vim.api.nvim_create_autocmd('CursorMoved', {
            buffer = bufnr,
            callback = function()
              filter_current_line(render.diagnostic_cache, namespace, bufnr, opts)
            end,
          })
          filter_current_line(diagnostics, namespace, bufnr, opts)
        else
          render.show(namespace, bufnr, diagnostics, opts)
        end
      end
    end,
    ---@param namespace number
    ---@param bufnr number
    hide = function(namespace, bufnr)
      local ns = vim.diagnostic.get_namespace(namespace)
      if ns.user_data.virt_improved_ns then
        render.hide(ns.user_data.virt_improved_ns, bufnr)
      end
    end,
  }
end

return M
