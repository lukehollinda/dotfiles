return {
  {
    'nvimtools/hydra.nvim',
    lazy = false,
    config = function()
      -- Resizing largly stolen from: https://github.com/0xm4n/resize.nvim/blob/main/lua/resize.lua
      local function isRightMost()
        local curWin = vim.fn.winnr()
        vim.cmd [[wincmd l]]
        local rightWin = vim.fn.winnr()
        if curWin == rightWin then
          return true
        else
          vim.cmd [[wincmd h]]
        return false
        end
      end

      local function isLeftMost()
        local curWin = vim.fn.winnr()
        vim.cmd [[wincmd h]]
        local leftWin = vim.fn.winnr()
        if curWin == leftWin then
          return true
        else
          vim.cmd [[wincmd l]]
          return false
        end
      end

      local function isBottomMost()
        local curWin = vim.fn.winnr()
        vim.cmd [[wincmd j]]
        local bottomWin = vim.fn.winnr()
        if curWin == bottomWin then
          return true
        else
          vim.cmd [[wincmd k]]
          return false
        end
      end

      local function isTopMost()
        local curWin = vim.fn.winnr()
        vim.cmd [[wincmd k]]
        local topWin = vim.fn.winnr()
        if curWin == topWin then
          return true
        else
          vim.cmd [[wincmd j]]
          return false
        end
      end

      local renderWindowSeperator = require("colorful-winsep.view").render

      local function ResizeLeft()
        if isRightMost() then
          vim.cmd [[wincmd 5 >]]
        else
          vim.cmd [[wincmd 5 <]]
        end
        renderWindowSeperator()
      end

      local function ResizeRight()
        if isRightMost() then
          vim.cmd [[wincmd 5 <]]
        else
          vim.cmd [[wincmd 5 >]]
        end
        renderWindowSeperator()
      end

      local function ResizeUp()
        if isBottomMost() then
          vim.cmd [[wincmd 5 +]]
        else
          vim.cmd [[wincmd 5 -]]
        end
        renderWindowSeperator()
      end

      local function ResizeDown()
        if isBottomMost() then
          vim.cmd [[wincmd 5 -]]
        else
          vim.cmd [[wincmd 5 +]]
        end
        renderWindowSeperator()
      end

      local Hydra = require('hydra')
      Hydra({
        name = 'Window',
        mode = 'n',
        body = '<C-w>',
        config = {
          -- invoke_on_body = true,
          -- hint = false,
        },
        heads = {
          -- Resize — all directions grow the current window (matching tmux pain-control)
          { 'H', ResizeLeft,  { desc = 'grow ←' } },
          { 'L', ResizeRight, { desc = 'grow →' } },
          { 'J', ResizeDown,  { desc = 'grow ↓' } },
          { 'K', ResizeUp,    { desc = 'grow ↑' } },
          -- Focus navigation — exit after action
          { 'h', '<C-w>h', { exit = true, desc = 'go ←' } },
          { 'j', '<C-w>j', { exit = true, desc = 'go ↓' } },
          { 'k', '<C-w>k', { exit = true, desc = 'go ↑' } },
          { 'l', '<C-w>l', { exit = true, desc = 'go →' } },
          -- Splits & window management — exit after action
          { 'v', '<C-w>v',      { exit = true, desc = 'vert split' } },
          { 's', '<C-w>s',      { exit = true, desc = 'horiz split' } },
          { 'w', '<C-w>w',      { exit = true, desc = 'next window' } },
          { '=', '<C-w>=',      { exit = true, desc = 'equalize' } },
          { 'o', '<C-w>o',      { exit = true, desc = 'only window' } },
          { 'q', '<C-w>q',      { exit = true, desc = 'close' } },
          { 'c', ':tabnew<CR>', { exit = true, desc = 'new tab' } },
          { '<Esc>', nil,        { exit = true, desc = false } },
        },
      })
    end,
  },
}
