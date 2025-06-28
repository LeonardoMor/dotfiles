return {
  'zapling/mason-conform.nvim',
  lazy = true,
  opts = {
    ignore_install = {
      'injected',
      'jqfmt',
      'xmllint',
      'prettier',
    },
  },
}
