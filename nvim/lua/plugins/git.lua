return {

  {
    -- Excellent Git plugin
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set('n', '<leader>gb', ':G blame<CR>', { desc = '[G]it [B]lame' })
      vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = '[G]it [S]tatus' })
      vim.keymap.set('n', '<leader>gl', ':G log --oneline<CR>', { desc = '[G]it [L]log' })
      vim.keymap.set('n', '<leader>gd', ':G diff<CR>', { desc = '[G]it [D]iff' })
    end
  },
  {
    'tpope/vim-rhubarb',
    -- Corperate Github URL defined elsewhere
  },
  {
    -- GBrowse handler for GitLab (gitlab.com works out of the box)
    -- To add self-hosted instances: vim.g.fugitive_gitlab_domains = { 'https://gitlab.yourcompany.com' }
    'shumphrey/fugitive-gitlab.vim',
    dependencies = { 'tpope/vim-fugitive' },
    lazy = false,
  },
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
              delay = 400,
      },
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}
