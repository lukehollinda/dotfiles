return {

  {
    'tpope/vim-fugitive',
    config = function()
      vim.keymap.set('n', '<leader>gb', ':G blame<CR>', { desc = '[G]it [B]lame' })
    end
  },
  {
    'tpope/vim-rhubarb',
    -- Corperate Github URL defined elsewhere
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
