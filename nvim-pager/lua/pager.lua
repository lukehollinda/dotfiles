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
  map({ 'n', 'x', 'o' }, ']]', function()
    vim.fn.search(anchor, 'W')
  end, { buffer = buf, desc = 'Next section' })

  map({ 'n', 'x', 'o' }, '[[', function()
    vim.fn.search(anchor, 'bW')
  end, { buffer = buf, desc = 'Previous section' })
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

local M = {}

-- Render a `capture-pane -e` dump through a terminal: the escape sequences are
-- consumed as highlights and the buffer text is left clean, so yanked text
-- carries no colour codes. Content reflows to the window width.
---@param opts? { anchor?: 'terminal'|'session' }
function M.render_ansi(opts)
  local anchor = anchors[(opts or {}).anchor] or anchors.terminal
  local expected = vim.api.nvim_buf_line_count(0)
  -- nvim_open_term writes into the buffer, which -R forbids
  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.bo.scrollback = 100000
  vim.api.nvim_open_term(0, {})
  vim.wait(5000, function()
    return vim.api.nvim_buf_line_count(0) >= expected
  end, 20)

  -- Allow tidying a line before yanking it. TermOpen also sets undolevels to
  -- -1, which would leave those edits unundoable.
  vim.bo.modifiable = true
  vim.bo.undolevels = vim.go.undolevels

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
