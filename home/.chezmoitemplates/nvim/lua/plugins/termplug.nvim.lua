    {
        'Ernest1338/termplug.nvim',
        {{- if eq .chezmoi.os "windows" }}
        opts = {
            shell = 'pwsh.exe -NoLogo'
        },
        {{- else }}
        opts = {},
        {{- end }}
        cmd = 'Term',
        keys = {
            {
                '<leader>tt',
                '<cmd>Term<CR>',
                mode = { 'n', 't' },
                desc = '[T]oggle terminal',
            },
        },
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
