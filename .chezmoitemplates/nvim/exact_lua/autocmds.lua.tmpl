vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Pin the buffer to any window that is fixed width or height',
  callback = function(args)
    local stickybuf = require 'stickybuf'
    if not stickybuf.is_pinned() and (vim.wo.winfixwidth or vim.wo.winfixheight) then
      stickybuf.pin()
    end
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position',
  pattern = '*',
  callback = function()
    local line = vim.fn.line '\'"'
    if line > 1 and line <= vim.fn.line '$' and vim.bo.filetype ~= 'commit' and vim.fn.index({ 'xxd', 'gitrebase' }, vim.bo.filetype) == -1 then
      vim.cmd 'normal! g`"'
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPre' }, {
  desc = 'Set correct type for chezmoi templates',
  group = vim.api.nvim_create_augroup('chezmoi-tmpl', { clear = true }),
  pattern = '{{ .chezmoi.sourceDir }}/**.tmpl',
  callback = function()
    vim.opt_local.filetype = 'gotmpl'
  end,
})
