return {
  'xiyaowong/transparent.nvim',
  lazy = false,
  config = function()
    require('transparent').setup()
    vim.keymap.set('n', '<leader>tr', '<cmd>TransparentToggle<CR>', { desc = '[T]oggle t[R]ansparency' })
  end,
}
