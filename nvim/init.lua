
-- Space as mapleader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.cmd([[set number relativenumber]])
vim.cmd([[setlocal scrolloff=999]])

-- Install package manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then 
	vim.fn.system { 
		'git', 
		'clone', 
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)


-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})


-- Sync clipboard between OS and Neovim.
vim.o.clipboard = 'unnamedplus'

