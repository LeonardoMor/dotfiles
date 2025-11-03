    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'Trouble' },
    opts = {},
    keys = {
        { '<leader>xd', '<cmd>Trouble diagnostics toggle<cr>', desc = '[T]rouble [D]iagnostics' },
        { '<leader>xD', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = '[T]rouble buffer [D]iagnostics' },
        { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = '[T]rouble [L]ocation list' },
        { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = '[T]rouble [Q]uickfix list' },
        {
            '[q',
            function()
                if require('trouble').is_open() then
                    require('trouble').prev { skip_groups = true, jump = true }
                else
                    local ok, err = pcall(vim.cmd.cprev)
                    if not ok then
                        vim.notify(err, vim.log.levels.ERROR)
                    end
                end
            end,
            desc = '[T]rouble Previous Trouble/[Q]uickfix Item',
        },
        {
            ']q',
            function()
                if require('trouble').is_open() then
                    require('trouble').next { skip_groups = true, jump = true }
                else
                    local ok, err = pcall(vim.cmd.cnext)
                    if not ok then
                        vim.notify(err, vim.log.levels.ERROR)
                    end
                end
            end,
            desc = '[T]rouble Next Trouble/[Q]uickfix Item',
        },
    },
