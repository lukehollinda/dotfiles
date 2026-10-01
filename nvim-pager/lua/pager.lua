local map = vim.keymap.set

-- Q to quickly close
map('n', '<C-q>', '<C-w>q')

-- Starship ends every prompt with the time and the character from
-- [character].success_symbol, giving the only reliable boundary between one
-- command's output and the next.
local prompt = [[^\[\d\d:\d\d:\d\d\] > ]]

-- Terminal buffers carry their own buffer-local [[ and ]] for OSC 133 prompt
-- marks, which a tmux capture does not emit, so these must be re-set on the
-- buffer there to take precedence.
local function map_command_motions(buf)
  map({ 'n', 'x', 'o' }, ']]', function()
    vim.fn.search(prompt, 'W')
  end, { buffer = buf, desc = 'Next command' })

  map({ 'n', 'x', 'o' }, '[[', function()
    vim.fn.search(prompt, 'bW')
  end, { buffer = buf, desc = 'Previous command' })
end

map_command_motions()

local M = {}

-- Render a `capture-pane -e` dump through a terminal: the escape sequences are
-- consumed as highlights and the buffer text is left clean, so yanked text
-- carries no colour codes. Content reflows to the window width.
function M.render_ansi()
  local expected = vim.api.nvim_buf_line_count(0)
  -- nvim_open_term writes into the buffer, which -R forbids
  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.bo.scrollback = 100000
  vim.api.nvim_open_term(0, {})
  vim.wait(5000, function()
    return vim.api.nvim_buf_line_count(0) >= expected
  end, 20)

  -- Terminal buffers force these off; this is a history view, not a shell
  vim.wo[0][0].number = true
  vim.wo[0][0].relativenumber = true

  map_command_motions(0)

  -- The pane's blank rows are captured too, so after `clear` the end of the
  -- buffer is empty padding. Land on the last line with content instead.
  vim.cmd('normal! G')
  if vim.fn.search([[\S]], 'bcW') == 0 then
    vim.cmd('normal! G')
  end
  vim.cmd('normal! zb')
end

return M
