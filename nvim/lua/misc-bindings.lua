local map = vim.keymap.set

map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Unhighlight search term
map('n', '<ESC>', ':noh<CR>')

-- Tabs (resize and other <C-w> bindings managed by hydra in plugins/hydra.lua)
map("n", "<c-w>c", ":tabnew<CR>")
