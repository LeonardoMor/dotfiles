    {
        'alexghergh/nvim-tmux-navigation',
        cmd = { 'NvimTmuxNavigateUp', 'NvimTmuxNavigateLeft', 'NvimTmuxNavigateDown', 'NvimTmuxNavigateRight' },
        keys = {
            { '<C-h>', '<cmd>NvimTmuxNavigateLeft<cr>' },
            { '<C-j>', '<cmd>NvimTmuxNavigateDown<cr>' },
            { '<C-k>', '<cmd>NvimTmuxNavigateUp<cr>' },
            { '<C-l>', '<cmd>NvimTmuxNavigateRight<cr>' },
            { '<C-\\>', '<cmd>NvimTmuxNavigateLastActive<cr>' },
        },
        config = function()
            require('nvim-tmux-navigation').setup {
                disable_when_zoomed = true,
            }
        end,
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
