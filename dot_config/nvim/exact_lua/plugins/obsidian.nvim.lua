return {
  'epwalsh/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  event = {
    'BufReadPre ' .. os.getenv 'HOME' .. '/source/repos/Codice/**',
    'BufNewFile ' .. os.getenv 'HOME' .. '/source/repos/Codice/**',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    workspaces = {
      {
        name = 'Codice',
        path = '~/source/repos/Codice',
      },
    },
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    ui = { enable = false },
  },
  -- config = function()
  --   vim.api.nvim_create_autocmd('FileType', {
  --     desc = 'Markdown Conceal for Obsidian vault files',
  --     group = vim.api.nvim_create_augroup('MarkdownConceal', { clear = true }),
  --     pattern = 'markdown',
  --     callback = function()
  --       local path = vim.fn.expand '%:p'
  --       if string.match(path, '^' .. vim.fn.expand '~/source/repos/Codice' .. '/') then
  --         vim.opt_local.conceallevel = 2
  --       end
  --     end,
  --   })
  -- end,
}
