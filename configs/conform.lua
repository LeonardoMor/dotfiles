local options = {
  formatters_by_ft = {
    sh = { "shfmt" },
    lua = { "stylua" },
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
  formatters = {
    shfmt = {
      prepend_args = { "--case-indent", "--indent", "0" },
    },
  },
}

require("conform").setup(options)