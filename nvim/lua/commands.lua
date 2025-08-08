-- Enable GBrowse to open git link
vim.api.nvim_create_user_command(
  'Browse',
  function (opts)
    vim.fn.system { 'open', opts.fargs[1] }
  end,
  { nargs = 1 }
)

-- Clear trailing whitespace when saving buffer to file
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    -- First elemenet in getpos(".") result is unneeded buffer number
    local position = vim.fn.getpos(".")
    table.remove(position, 1)

    -- Strip trailing whitespace
    vim.cmd([[%s/\s\+$//e]])

    vim.fn.cursor(position)
  end,
  -- command = [[%s/\s\+$//e]],
})

-- Highlight on Yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


