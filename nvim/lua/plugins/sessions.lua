return {
  {
    'rmagatti/auto-session',
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      -- log_level = 'debug',
      auto_create = function()
        local cmd = 'git rev-parse --is-inside-work-tree'
        return vim.fn.system(cmd) == 'true\n'
      end,
    },
  }

}
