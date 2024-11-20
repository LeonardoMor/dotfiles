return {
  'MeanderingProgrammer/markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('render-markdown').setup {}
  end,
  -- cond = function()
  --   local path = vim.fn.expand '%:p'
  --   return not string.match(path, '^' .. vim.fn.expand '~/source/repos/Codice' .. '/')
  -- end,
  cmd = { 'RenderMarkdown' },
  ft = { 'markdown' },
}
