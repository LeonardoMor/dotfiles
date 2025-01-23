return {
  'rshkarin/mason-nvim-lint',
  lazy = true,
  opts = {
    ensure_installed = {
      'shellcheck',
    },
    automatic_installation = true,
  },
}
