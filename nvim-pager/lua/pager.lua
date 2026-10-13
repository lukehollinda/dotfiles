local map = vim.keymap.set

-- Q to quickly close
map('n', '<C-q>', '<C-w>q')

-- What separates one unit of output from the next, per kind of capture. For a
-- terminal that is the starship prompt, which ends with the time and the
-- character from [character].success_symbol. For a rendered Claude session it
-- is the turn headers written by claude-transcript.jq.
local anchors = {
  terminal = [[^\[\d\d:\d\d:\d\d\] > ]],
  session = [[^# ❯ you\|^# ✻ claude]],
}

-- Terminal buffers carry their own buffer-local [[ and ]] for OSC 133 prompt
-- marks, which a tmux capture does not emit, so these must be re-set on the
-- buffer there to take precedence.
local function map_command_motions(buf, anchor)
  local function jump(flags)
    return function()
      if vim.fn.search(anchor, flags) == 0 then
        return
      end
      -- Not while an operator is pending: a normal command there would run
      -- inside the operator, and the view is about to change regardless.
      if not vim.startswith(vim.fn.mode(1), 'no') then
        vim.cmd('normal! zz')
      end
    end
  end

  map({ 'n', 'x', 'o' }, ']]', jump('W'), { buffer = buf, desc = 'Next section' })
  map({ 'n', 'x', 'o' }, '[[', jump('bW'), { buffer = buf, desc = 'Previous section' })
end

map_command_motions(nil, anchors.terminal)

-- Chrome shared by both views: numbers, the tint that marks this as neither the
-- terminal nor an editor instance, and motions for whatever anchors this
-- capture carries. Set winhighlight wholesale, since on a capture TermOpen has
-- already remapped StatusLine to StatusLineTerm.
local function decorate(anchor)
  vim.wo[0][0].number = true
  vim.wo[0][0].relativenumber = true

  vim.api.nvim_set_hl(0, 'PagerHistoryNormal', { bg = '#102a33' })
  vim.api.nvim_set_hl(0, 'PagerHistoryStatus', { fg = '#191724', bg = '#9ccfd8', bold = true })
  vim.wo[0][0].winhighlight = table.concat({
    'Normal:PagerHistoryNormal',
    'NormalNC:PagerHistoryNormal',
    'StatusLine:PagerHistoryStatus',
    'StatusLineNC:PagerHistoryStatus',
  }, ',')

  map_command_motions(0, anchor)
end

-- A terminal grid hard-wraps at its own width, so a logical line survives as a
-- single buffer line only if the grid is at least as wide as the longest one.
-- Width is measured in bytes of the text with SGR sequences removed, which can
-- only over-estimate cells, and so never leaves a row to wrap. The budget stops
-- one pathological line widening every row of a 50k-line history.
local GRID_CELL_BUDGET = 10 * 1024 * 1024

local function grid_width(lines)
  local widest = 0
  for _, line in ipairs(lines) do
    local text = line:gsub('\27%[[%d;:?]*%a', '')
    if #text > widest then
      widest = #text
    end
  end
  local cap = math.floor(GRID_CELL_BUDGET / math.max(#lines, 1))
  return math.max(vim.o.columns, math.min(widest, cap))
end

local M = {}

-- Render a `capture-pane -eJ` dump through a terminal: the escape sequences are
-- consumed as highlights and the buffer text is left clean, so yanked text
-- carries no colour codes. The grid is sized to the capture and then frozen, so
-- each captured line stays one buffer line for 'wrap' to soft wrap.
---@param opts? { anchor?: 'terminal'|'session' }
function M.render_ansi(opts)
  local anchor = anchors[(opts or {}).anchor] or anchors.terminal
  local raw = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local columns = vim.o.columns

  -- nvim_open_term writes into the buffer, which -R forbids
  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.bo.scrollback = 100000
  vim.o.columns = grid_width(raw)
  local chan = vim.api.nvim_open_term(0, {})
  local settled, stable = -1, 0
  vim.wait(10000, function()
    local count = vim.api.nvim_buf_line_count(0)
    stable = (count == settled) and stable + 1 or 0
    settled = count
    return stable >= 3 and count >= #raw
  end, 20)

  -- Closing the channel freezes the grid: restoring columns while it is live
  -- reflows the rows still on screen and splits their long lines again. The
  -- close leaves a "[Terminal closed]" overlay behind.
  pcall(vim.fn.chanclose, chan)
  vim.o.columns = columns
  vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace('nvim.terminal.exitmsg'), 0, -1)

  -- Allow tidying a line before yanking it. TermOpen also sets undolevels to
  -- -1, which would leave those edits unundoable.
  vim.bo.modifiable = true
  vim.bo.undolevels = vim.go.undolevels

  -- Soft wrap in place of the grid's hard wrap, so a long line stays whole for
  -- a yank or a gx. TermOpen turns 'wrap' off.
  vim.wo[0][0].wrap = true

  -- `capture-pane -J` pads every row out to the source pane width.
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    lines[i] = line:gsub('%s+$', '')
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  decorate(anchor)

  -- The pane's blank rows are captured too, so after `clear` the end of the
  -- buffer is empty padding. Land on the last line with content instead.
  vim.cmd('normal! G')
  if vim.fn.search([[\S]], 'bcW') == 0 then
    vim.cmd('normal! G')
  end
  vim.cmd('normal! zb')
end

-- A rendered Claude session is markdown, not terminal output, so it gets a real
-- markdown buffer where treesitter and render-markdown apply. Avoiding a
-- terminal also means no reflow, so long lines survive.
function M.render_session()
  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.bo.filetype = 'markdown'

  decorate(anchors.session)

  vim.cmd('normal! G')
  vim.cmd('normal! zb')
end

return M
