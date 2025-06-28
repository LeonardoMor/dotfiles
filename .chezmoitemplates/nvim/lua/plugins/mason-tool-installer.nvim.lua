return {
  'WhoIsSethDaniel/mason-tool-installer.nvim',
  lazy = true,
  opts = {
    ensure_installed = { 'shellcheck', 'checkmake' },
    auto_update = true,
  },
}
