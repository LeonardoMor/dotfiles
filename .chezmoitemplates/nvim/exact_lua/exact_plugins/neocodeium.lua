return {
  'monkoose/neocodeium',
  dev = false,
  event = 'InsertEnter',
  cmd = 'NeoCodeium',
  opts = {},
  keys = {
    {
      '<A-h>',
      function()
        require('neocodeium').accept()
      end,
      mode = 'i',
      desc = 'Accept full suggestion',
    },
    {
      '<A-]>',
      function()
        require('neocodeium').cycle_or_complete()
      end,
      mode = 'i',
      desc = 'Cycle completions',
    },
    {
      '<A-[>',
      function()
        require('neocodeium').cycle_or_complete(-1)
      end,
      mode = 'i',
      desc = 'Cycle completions backwards',
    },
    {
      '<C-Bslash>',
      function()
        require('neocodeium').clear()
      end,
      mode = 'i',
      desc = 'Clear completions',
    },
    {
      '<A-l>',
      function()
        require('neocodeium').accept_word()
      end,
      mode = 'i',
      desc = 'Accept word',
    },
    {
      '<A-;>',
      function()
        require('neocodeium').accept_line()
      end,
      mode = 'i',
      desc = 'Accept line',
    },
    {
      '<leader>cc',
      '<cmd>NeoCodeium chat<CR>',
      mode = 'n',
      desc = 'Open Codeium chat',
    },
  },
}
