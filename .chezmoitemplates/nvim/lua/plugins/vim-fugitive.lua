return {
  -- https://raw.githubusercontent.com/tpope/vim-fugitive/master/doc/fugitive.txt
  'tpope/vim-fugitive',
  dependencies = {
    'stevearc/stickybuf.nvim',
  },
  cmd = {
    'G',
    'Git',
    'Gdiffsplit',
    'Gvdiffsplit',
    'Gread',
    'Gwrite',
    'Ggrep',
    'GMove',
    'GDelete',
    'GBrowse',
    'GRemove',
    'GRename',
    'Glgrep',
    'Gedit',
  },
  keys = {
    { '<leader>gg', '<cmd>G<CR>', desc = 'git status' },
    { '<leader>gc', '<cmd>G commit<CR>', desc = 'git commit' },
    { '<leader>gs', '<cmd>Gwrite<CR>', desc = 'git save and stage' },
    { '<leader>gp', '<cmd>G push<CR>', desc = 'git push' },
  },
}
