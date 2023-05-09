local M = {}

M.severity = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  HINT = 4,
}

local function to_severity(severity)
  if type(severity) == 'string' then
    return assert(M.severity[string.upper(severity)], string.format('Invalid severity: %s', severity))
  end
  return severity
end

local function filter_by_severity(severity, diagnostics)
  if not severity then
    return diagnostics
  end

  if type(severity) ~= 'table' then
    severity = to_severity(severity)
    return vim.tbl_filter(function(t)
      return t.severity == severity
    end, diagnostics)
  end

  local min_severity = to_severity(severity.min) or M.severity.HINT
  local max_severity = to_severity(severity.max) or M.severity.ERROR

  return vim.tbl_filter(function(t)
    return t.severity <= min_severity and t.severity >= max_severity
  end, diagnostics)
end

---@private
local function get_bufnr(bufnr)
  if not bufnr or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

---@private
local function diagnostic_lines(diagnostics)
  if not diagnostics then
    return {}
  end
  local diagnostics_by_line = {}
  for _, diagnostic in ipairs(diagnostics) do
    local line_diagnostics = diagnostics_by_line[diagnostic.lnum]
    if not line_diagnostics then
      line_diagnostics = {}
      diagnostics_by_line[diagnostic.lnum] = line_diagnostics
    end
    table.insert(line_diagnostics, diagnostic)
  end
  return diagnostics_by_line
end

M.diagnostic_cache = {}

---@private
local function count_sources(bufnr)
  local seen = {}
  local count = 0
  for _, namespace_diagnostics in pairs(M.diagnostic_cache[bufnr]) do
    for _, diagnostic in ipairs(namespace_diagnostics) do
      if diagnostic.source and not seen[diagnostic.source] then
        seen[diagnostic.source] = true
        count = count + 1
      end
    end
  end
  return count
end

---@private
local function prefix_source(diagnostics)
  return vim.tbl_map(function(d)
    if not d.source then
      return d
    end

    local t = vim.deepcopy(d)
    t.message = string.format('%s: %s', d.source, d.message)
    return t
  end, diagnostics)
end

---@private
local function reformat_diagnostics(format, diagnostics)
  vim.validate({
    format = { format, 'f' },
    diagnostics = { diagnostics, 't' },
  })

  local formatted = vim.deepcopy(diagnostics)
  for _, diagnostic in ipairs(formatted) do
    diagnostic.message = format(diagnostic)
  end
  return formatted
end

--- Get virtual text chunks to display using |nvim_buf_set_extmark()|.
---
---@private
local function get_virt_text_chunks(line_diags, opts)
  if #line_diags == 0 then
    return nil
  end

  local highlight_groups = {
    [vim.diagnostic.severity.ERROR] = 'DiagnosticVirtualTextError',
    [vim.diagnostic.severity.WARN] = 'DiagnosticVirtualTextWarn',
    [vim.diagnostic.severity.INFO] = 'DiagnosticVirtualTextInfo',
    [vim.diagnostic.severity.HINT] = 'DiagnosticVirtualTextHint',
  }

  opts = opts or {}
  local prefix = opts.prefix or '●'
  local suffix = opts.suffix or ''
  local spacing = opts.spacing or 4

  -- Create a little more space between virtual text and contents
  local virt_texts = { { string.rep(' ', spacing) } }

  for i = 1, #line_diags do
    local resolved_prefix = prefix
    if type(prefix) == 'function' then
      resolved_prefix = prefix(line_diags[i]) or ''
    end
    table.insert(virt_texts, { resolved_prefix, highlight_groups[line_diags[i].severity] })
  end

  local diagnostic = line_diags[#line_diags]

  local msg
  if diagnostic.code and opts.code == true then
    msg = string.format('%s: %s', diagnostic.code, diagnostic.message)
  else
    msg = diagnostic.message
  end

  if msg then
    if type(suffix) == 'function' then
      suffix = suffix(diagnostic) or ''
    end
    table.insert(virt_texts, {
      string.format(' %s%s', msg:gsub('\r', ''):gsub('\n', '  '), suffix),
      highlight_groups[diagnostic.severity],
    })

    return virt_texts
  end
end

---@param namespace number
---@param bufnr number
---@param diagnostics table
---@param opts boolean|Opts
function M.show(namespace, bufnr, diagnostics, opts)
  vim.validate({
    namespace = { namespace, 'n' },
    bufnr = { bufnr, 'n' },
    diagnostics = {
      diagnostics,
      vim.tbl_islist,
      'a list of diagnostics',
    },
    opts = { opts, 't', true },
  })

  local ns = vim.diagnostic.get_namespace(namespace)
  local virt_improved_ns = ns.user_data.virt_improved_ns
  vim.api.nvim_buf_clear_namespace(bufnr, virt_improved_ns, 0, -1)

  if #diagnostics == 0 then
    return
  end

  bufnr = get_bufnr(bufnr)
  opts = opts or {}

  table.sort(diagnostics, function(a, b)
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    else
      return a.col < b.col
    end
  end)

  local severity
  if opts.virtual_improved then
    if opts.virtual_improved.format then
      diagnostics = reformat_diagnostics(opts.virtual_improved.format, diagnostics)
    end
    if opts.virtual_improved.source and (opts.virtual_improved.source ~= 'if_many' or count_sources(bufnr) > 1) then
      diagnostics = prefix_source(diagnostics)
    end
    if opts.virtual_improved.severity then
      severity = opts.virtual_improved.severity
    end
  end

  local buffer_line_diagnostics = diagnostic_lines(diagnostics)
  for line, line_diagnostics in pairs(buffer_line_diagnostics) do
    if severity then
      line_diagnostics = filter_by_severity(severity, line_diagnostics)
    end
    local virt_texts = get_virt_text_chunks(line_diagnostics, opts.virtual_improved)
    if virt_texts then
      vim.api.nvim_buf_set_extmark(bufnr, virt_improved_ns, line, 0, {
        hl_mode = 'combine',
        virt_text = virt_texts,
      })
    end
  end
end

---@param namespace number
---@param bufnr number
function M.hide(namespace, bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

return M
