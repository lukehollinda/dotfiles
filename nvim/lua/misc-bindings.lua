local map = vim.keymap.set

map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Unhighlight search term
map('n', '<ESC>', ':noh<CR>')

-- resize windows
map("n", "<c-w>H", ":vertical resize +5<CR>")
map("n", "<c-w>L", ":vertical resize -5<CR>")
map("n", "<c-w>K", ":resize +5<CR>")
map("n", "<c-w>J", ":resize -5<CR>")
