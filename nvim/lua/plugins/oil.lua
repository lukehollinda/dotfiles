return {

  {
    'stevearc/oil.nvim',
    opts = {
      default_file_explorer = true,
      use_default_keymaps = true,
      view_options = {
        show_hidden = true,
      },
      keymaps={
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    vim.api.nvim_set_keymap("n", "<leader>E", ":Oil<cr>", { noremap = true, silent = true })

  },
}




