    {
        'utilyre/barbecue.nvim',
        name = 'barbecue',
        version = '*',
        dependencies = {
            {
                'SmiteshP/nvim-navic',
                opts = {
                    lsp = {
                        auto_attach = true,
                        preference = { 'basedpyright', 'bashls' },
                    },
                },
            },
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            attach_navic = false,
        },
        event = 'LspAttach',
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
