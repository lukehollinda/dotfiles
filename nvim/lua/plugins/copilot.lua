return {
  {
    'github/copilot.vim',
    init = function()
      -- Disable Copilot by default
      vim.g.copilot_enabled = false
    end,

    config = function()
      -- Toggle copilot with <leader>cc
      function Toggle_copilot()
        if vim.g.copilot_enabled then
          vim.g.copilot_enabled = false
          print("Copilot disabled")
        else
          vim.g.copilot_enabled = true
          print("Copilot enabled")
        end
      end

      vim.api.nvim_set_keymap('n', '<leader>cc', ':lua Toggle_copilot()<CR>', { noremap = true, silent = true, desc = 'Toggle Copilot'})
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
      mappings = {
        show_diff = {
          normal = '<C-s>',
        },
      },
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}
