local map = vim.keymap.set

map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Unhighlight search term
map('n', '<ESC>', ':noh<CR>')

-- Tabs (resize and other <C-w> bindings managed by hydra in plugins/hydra.lua)
map("n", "<c-w>c", ":tabnew<CR>")

-- Copy path of current file, relative to cwd, to the clipboard
map("n", "<leader>yy", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Yank relative file path" })
