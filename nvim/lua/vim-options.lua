

vim.cmd([[set number relativenumber]])
vim.cmd([[setlocal scrolloff=999]])

local map = vim.api.nvim_set_keymap

-- leader-h unhighlight search
map('n', '<leader>h', ':noh<CR>', {noremap = true, silent = false})

