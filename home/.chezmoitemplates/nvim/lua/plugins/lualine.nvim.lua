    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      sections = {
        lualine_a = { { 'mode', icon = '' } },
      },
      extensions = {
        'aerial',
        'fugitive',
        'lazy',
        'mason',
        'neo-tree',
        'quickfix',
        'trouble',
      },
      -- tabline = {
      --   lualine_a = { 'buffers' },
      --   lualine_z = { 'tabs' },
      -- },
    },
    event = 'BufWinEnter',
