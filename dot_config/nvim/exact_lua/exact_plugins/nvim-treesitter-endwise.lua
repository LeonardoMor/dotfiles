return {
  'RRethy/nvim-treesitter-endwise',
  config = function()
    require('nvim-treesitter.configs').setup {
      endwise = {
        enable = true,
      },
    }
  end,
  ft = { 'lua', 'rb', 'vim', 'sh', 'fish', 'jl' },
}
