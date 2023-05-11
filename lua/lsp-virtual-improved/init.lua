local M = {}

local render = require('lsp-virtual-improved.render')

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
---@field code boolean|nil

-- Registers a wrapper-handler to render lsp virtual text.
-- This should usually only be called once, during initialisation.
function M.setup()
  local function _augroup(name)
    return vim.api.nvim_create_augroup('LspVirtualImproved_' .. name, { clear = true })
  end

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = _augroup('update_diagnostic_cache'),
    pattern = '*',
    callback = function(args)
      render.update_diagnostic_cache(args.data.buffer, args.data.diagnostics)
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
              render.filter_current_line_cached(namespace, bufnr, opts)
            end,
          })
          render.filter_current_line(namespace, bufnr, diagnostics, opts)
        else
          render.show(namespace, bufnr, diagnostics, opts)
        end
      end
    end,

    ---@param namespace number
    ---@param bufnr number
    hide = function(namespace, bufnr)
      local ns = vim.diagnostic.get_namespace(namespace)
      if ns.user_data.virt_improved_ns and vim.api.nvim_buf_is_valid(bufnr) then
        render.hide(ns.user_data.virt_improved_ns, bufnr)
      end
    end,
  }
end

return M
