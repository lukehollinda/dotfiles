return {

  'tpope/vim-fugitive',

  {
    'tpope/vim-rhubarb',
    init = function ()
      vim.g.github_enterprise_urls = {'https://github.ihs.demonware.net'}
    end
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
