return {
  'github/copilot.vim',

  init = function()
    -- disable by default
    vim.g.copilot_filetypes = {
            ["*"] = false,
    }
    -- explicitly request for copilot suggestions on Ctrl-C
    vim.keymap.set('i', '<C-C>', '<Plug>(copilot-suggest)')
  end,

}
