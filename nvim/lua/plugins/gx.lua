return {

  "chrishrb/gx.nvim",
  keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
  cmd = { "Browse" },
  init = function ()
    vim.g.netrw_nogx = 1 -- disable netrw gx
  end,
  dependencies = { "nvim-lua/plenary.nvim" }, -- Required for Neovim < 0.10.0
  submodules = false, -- not needed, submodules are required only for tests

  config = function() require("gx").setup {
    open_browser_app = "open",
    open_browser_args = {},
    handlers = {
      github = true,
      search = true,
      url = true,
      -- go = true,
      -- Additional optinos for markdown, commit??
      jira = { -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
        name = "jira", -- set name of handler
        handle = function(mode, line, _)
          local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
          if ticket ~= nil and ticket ~= '' then
              return "https://dev.activision.com/jira/browse/" .. ticket
          end
        end
      },
    },
    handler_options = {
      search_engine = "google",
      select_for_search = true,
      git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
      git_remote_push = false, -- use the push url for git issue linking,
    },
  } end,
}
