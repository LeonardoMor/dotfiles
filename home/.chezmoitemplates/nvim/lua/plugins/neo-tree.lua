    {
        -- Neo-tree is a Neovim plugin to browse the file system
        -- https://github.com/nvim-neo-tree/neo-tree.nvim

        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
            'MunifTanjim/nui.nvim',
        },
        lazy = false,
        keys = {
            { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal' },
        },
        opts = {
            filesystem = {
                window = {
                    mappings = {
                        ['\\'] = 'close_window',
                    },
                },
            },
            event_handlers = {
                {
                    event = 'file_open_requested',
                    handler = function()
                        require('neo-tree.command').execute { action = 'close' }
                    end,
                },
                {
                  event = "neo_tree_buffer_enter",
                  handler = function(arg)
                    vim.o.number = true
                    vim.o.relativenumber = true
                  end,
                },
            },
        },
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
