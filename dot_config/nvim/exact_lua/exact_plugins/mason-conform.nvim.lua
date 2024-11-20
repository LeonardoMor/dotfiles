return {
  'zapling/mason-conform.nvim',
  lazy = true,
  opts = {
    ignore_install = {
      'gofmt',
      'injected',
      'jqfmt',
      'prettier',
      'xmllint',
    },
  },
}
