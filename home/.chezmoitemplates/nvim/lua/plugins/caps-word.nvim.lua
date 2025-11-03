    {
        'dmtrKovalenko/caps-word.nvim',
        lazy = true,
        opts = {},
        keys = {
            {
                mode = { 'i', 'n' },
                '<C-s>',
                "<cmd>lua require('caps-word').toggle()<CR>",
            },
        },
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
