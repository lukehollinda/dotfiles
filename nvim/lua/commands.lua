-- Enable GBrowse to open git link
vim.api.nvim_create_user_command(
  'Browse',
  function (opts)
    vim.fn.system { 'open', opts.fargs[1] }
  end,
  { nargs = 1 }
)

-- Alias Gitsigns to Gs
vim.api.nvim_create_user_command(
  'Gs',
  function(opts)
    vim.cmd('Gitsigns ' .. opts.args)
  end,
  {
    nargs = '*',
    bang = true,
    desc = 'Alias for :Gitsigns',
  }
)


-- Two trailing spaces are a hard line break in markdown
local keeps_trailing_whitespace = { markdown = true }

-- Clear trailing whitespace when saving buffer to file
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function(event)
    if not vim.bo[event.buf].modifiable or keeps_trailing_whitespace[vim.bo[event.buf].filetype] then
      return
    end

    -- First element in getpos(".") result is unneeded buffer number
    local position = vim.fn.getpos(".")
    table.remove(position, 1)

    -- Strip trailing whitespace
    vim.cmd([[%s/\s\+$//e]])

    vim.fn.cursor(position)
  end,
})

-- Highlight on Yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Common Typos
vim.api.nvim_command('command Wq wq')
vim.api.nvim_command('command Q q')
vim.api.nvim_command('command W w')

