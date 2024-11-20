return {
  'alker0/chezmoi.vim',
  lazy = false,
  init = function()
    vim.g['chezmoi#use_tmp_buffer'] = true
    require('nvim-treesitter.configs').setup {
      highlight = {
        disable = function()
          if string.find(vim.bo.filetype, 'chezmoitmpl') then
            return true
          end
        end,
      },
    }
  end,
}
