

vim.cmd([[set number relativenumber]])
vim.cmd([[setlocal scrolloff=999]])

local map = vim.api.nvim_set_keymap

-- leader-h unhighlight search
map('n', '<leader>h', ':noh<CR>', {noremap = true, silent = false})

-- snap left and right
map('n', 'H', '^', {noremap = true, silent = false})
map('n', 'L', '$', {noremap = true, silent = false})

-- clear file whitespace
map("n", "<leader>cw", [[ :%s/\s\+$//g<CR>]], { noremap = true, silent = false})

-- Mystical line to provide relative line numbers in netrw
vim.g.netrw_bufsettings = 'noma nomod nu rnu nobl nowrap ro'

