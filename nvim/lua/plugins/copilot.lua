return {
  {
    'github/copilot.vim',
    init = function()
      -- -- disable by default
      -- vim.g.copilot_filetypes = {
      --   ["*"] = false,
      -- }
      -- -- explicitly request for copilot suggestions on Ctrl-C
      -- vim.keymap.set('i', '<C-C>', '<Plug>(copilot-suggest)')
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}
