return {
  'windwp/nvim-ts-autotag',
  ft = { 'html', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'markdown' },
  config = function()
    require('nvim-ts-autotag').setup()
  end,
}
