return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- Default config here: https://github.com/nvim-lualine/lualine.nvim?tab=readme-ov-file#default-configuration
  opts = {
    options = {
      theme = "auto",
    },
    sections = {
      lualine_z = {
        -- Custom location. line number : total lines
        function ()
          local line = vim.fn.line('.')
          local last = vim.fn.line('$')
          return string.format('%3d:%-2d', line, last)
        end
      }
    }
  }
}
