local map = vim.keymap.set

map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
map('n', 'k', "v:count == 0 ? 'gkzz' : 'kzz'", { expr = true, silent = true })
map('n', 'j', "v:count == 0 ? 'gjzz' : 'jzz'", { expr = true, silent = true })

-- Unhighlight search term
map('n', '<ESC>', ':noh<CR>')

-- resize windows
map("n", "<c-w>H", ":vertical resize +5<CR>")
map("n", "<c-w>L", ":vertical resize -5<CR>")
map("n", "<c-w>K", ":resize +5<CR>")
map("n", "<Up>J", ":resize -5<CR>")
