-- Relative line numbers on by default
vim.opt.relativenumber = true
-- Don't keep search highlight, but highlight as you type
vim.opt.hlsearch = false
vim.opt.incsearch = true
-- Disable Codeium default bindings
vim.g.codeium_disable_bindings = 1
-- Briefly highlight yanked text
vim.api.nvim_create_autocmd ('TextYankPost', {
    group = vim.api.nvim_create_augroup ('highlight_yank', {}),
    desc = 'Hightlight selection on yank',
    pattern = '*',
    callback = function ()
      vim.highlight.on_yank { higroup = 'IncSearch', timeout = 125 }
    end,
  })  