return {
  'aaronik/treewalker.nvim',

  -- and setup() does not need to be called, so the whole opts block is optional.
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
}
