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
        ['<C-p>'] = {
           function()
            local oil = require 'oil'
            local util = require 'oil.util'

            local entry = oil.get_cursor_entry()
            if not entry then
              vim.notify("Could not find entry under cursor", vim.log.levels.ERROR)
              return
            end
            local winid = util.get_preview_win()
            if winid then
              local cur_id = vim.w[winid].oil_entry_id
              if entry.id == cur_id then
                vim.api.nvim_win_close(winid, true)
                if util.is_floating_win() then
                  local layout = require("oil.layout")
                  local win_opts = layout.get_fullscreen_win_opts()
                  vim.api.nvim_win_set_config(0, win_opts)
                end
                return
              end
            end
            oil.open_preview({vertical=true,split='botright'})
          end,
        },
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    vim.api.nvim_set_keymap("n", "<leader>E", ":Oil<cr>", { noremap = true, silent = true })

  },
}
