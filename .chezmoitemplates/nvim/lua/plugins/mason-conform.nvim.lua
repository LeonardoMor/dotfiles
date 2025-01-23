return {
  'zapling/mason-conform.nvim',
  lazy = true,
  opts = {
    ignore_install = {
      'gofmt',
      'injected',
      'jqfmt',
      'xmllint',
{{- if ne .chezmoi.os "windows" }}
      'prettier',
{{- end }}
    },
  },
}
