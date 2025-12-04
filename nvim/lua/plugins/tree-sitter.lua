return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {  'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'go', 'yaml' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      enable = true,
    },
  },
  {
    'aaronik/treewalker.nvim',
    opts = {
      -- Whether to briefly highlight the node after jumping to it
      highlight = true,
      -- How long should above highlight last (in ms)
      highlight_duration = 250,
      -- The color of the above highlight. Must be a valid vim highlight group.
      -- (see :h highlight-group for options)
      highlight_group = 'CursorLine',
    },
      -- movement
      vim.keymap.set({ 'n', 'v' }, '<Up>', '<cmd>Treewalker Up<cr>', { silent = true }),
      vim.keymap.set({ 'n', 'v' }, '<Down>', '<cmd>Treewalker Down<cr>', { silent = true }),
      vim.keymap.set({ 'n', 'v' }, '<Left>', '<cmd>Treewalker Left<cr>', { silent = true }),
      vim.keymap.set({ 'n', 'v' }, '<Right>', '<cmd>Treewalker Right<cr>', { silent = true }),
  },

      -- There are additional nvim-treesitter modules that you can use to interact
      -- with nvim-treesitter. You should go explore a few and see what interests you:
      --
      --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
      --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
      --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
