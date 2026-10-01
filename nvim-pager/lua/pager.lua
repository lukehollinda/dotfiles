local map = vim.keymap.set

-- Q to quickly close
map('n', '<C-q>', '<C-w>q')

-- Starship ends every prompt with the time and the character from
-- [character].success_symbol, giving the only reliable boundary between one
-- command's output and the next.
local prompt = [[^\[\d\d:\d\d:\d\d\] > ]]

map('n', ']]', function()
  vim.fn.search(prompt, 'W')
end, { desc = 'Next command' })

map('n', '[[', function()
  vim.fn.search(prompt, 'bW')
end, { desc = 'Previous command' })

