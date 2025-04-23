-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gkzz' : 'kzz'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gjzz' : 'jzz'", { expr = true, silent = true })

-- Unhighlight search term
vim.keymap.set('n', '<LEADER>H', ':noh<CR>')
