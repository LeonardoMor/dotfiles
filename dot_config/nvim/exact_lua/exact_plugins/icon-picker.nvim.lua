return {
  'ziontee113/icon-picker.nvim',
  opts = {
    disable_legacy_commands = true,
  },
  keys = {
    { '<Leader><Leader>i', '<cmd>IconPickerNormal<cr>', noremap = true, silent = true },
    { '<Leader><Leader>y', '<cmd>IconPickerYank<cr>', noremap = true, silent = true },
  },
}
