-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Tabs bindings
vim.keymap.set('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = '[L]ast [Tab]' })
vim.keymap.set('n', '<leader><tab>o', '<cmd>tabonly<cr>', { desc = 'Close [O]ther [Tab]s' })
vim.keymap.set('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = '[F]irst [Tab]' })
vim.keymap.set('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = 'New [Tab]' })
vim.keymap.set('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next [Tab]' })
vim.keymap.set('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Close [Tab]' })
vim.keymap.set('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous [Tab]' })

-- Windows bindings
-- Resize window using arrow keys
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase [W]indow Height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease [W]indow Height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease [W]indow Width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase [W]indow Width' })

-- Manipulate windows
-- NOTE: `remap = true` will allow you to use existing mappings in the right hand side of the definition
vim.keymap.set('n', '<leader>ww', '<C-W>p', { desc = 'Other [W]indow', remap = true })
vim.keymap.set('n', '<leader>wd', '<C-W>c', { desc = '[D]elete [W]indow', remap = true })
vim.keymap.set('n', '<leader>w-', '<C-W>s', { desc = 'Split [W]indow Below', remap = true })
vim.keymap.set('n', '<leader>w|', '<C-W>v', { desc = 'Split [W]indow Right', remap = true })
vim.keymap.set('n', '<leader>-', '<C-W>s', { desc = 'Split [W]indow Below', remap = true })
vim.keymap.set('n', '<leader>|', '<C-W>v', { desc = 'Split [W]indow Right', remap = true })
vim.keymap.set('n', '<leader>wm', function()
  require('maximize').toggle()
end, { desc = 'Toggle [M]aximize [W]indow' })

-- Buffer bindings
vim.keymap.set('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev [B]uffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<cr>', { desc = 'Next [B]uffer' })
vim.keymap.set('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other [B]uffer' })

--[[
TODO: This function is bad and produces errors on some situations.
Eventually, implement a version of this:
https://github.com/domeniczz/.dotfiles/blob/313c124d564feb023ea964a15ddffa68a112ad36/.config/nvim/lua/config/utils.lua#L153
]]
local function bufremove(buf)
  buf = buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

  if vim.bo.modified then
    local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
    if choice == 0 or choice == 3 then -- 0 for <Esc>/<C-c> and 3 for Cancel
      return
    end
    if choice == 1 then -- Yes
      vim.cmd.write()
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    -- Check if this window is the only one showing this buffer
    if #vim.fn.win_findbuf(buf) == 1 then
      -- Close the window if it's the last one showing this buffer
      vim.api.nvim_win_close(win, false)
    else
      -- If there are other windows showing this buffer, just switch to another buffer
      local alt = vim.fn.bufnr '#'
      if alt ~= buf and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
      else
        vim.cmd.bprevious { args = { win }, bang = true }
      end
    end
  end

  -- Delete the buffer if it's still valid after handling the windows
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.cmd, 'bdelete! ' .. buf)
  end
end

vim.keymap.set('n', '<leader>bd', bufremove, { desc = '[D]elete [B]uffer' })

-- Move lines
vim.keymap.set('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move Line Down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move Line Up' })
vim.keymap.set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Line Down' })
vim.keymap.set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Line Up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move Line Down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move Line Up' })

-- Add undo break-points
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')
vim.keymap.set('i', ';', ';<c-g>u')

-- Better indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Commenting
vim.keymap.set('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
vim.keymap.set('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

-- File mappings
vim.keymap.set('n', '<leader>fn', '<cmd>enew<cr>', { desc = '[N]ew [F]ile' })
vim.keymap.set('n', '<leader>fs', '<cmd>up<cr>', { desc = '[S]ave [F]ile if changed' })

-- Diagnostics
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go { severity = severity }
  end
end
vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Diagnostics Line Diagnostics' })
vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Diagnostics Next Diagnostic' })
vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Diagnostics Prev Diagnostic' })
vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Diagnostics Next Error' })
vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Diagnostics Prev Error' })
vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Diagnostics Next Warning' })
vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Diagnostics Prev Warning' })

-- Toggles
vim.keymap.set('n', '<leader>ta', '<cmd>AerialToggle<CR>', { desc = 'Toggles Aerial outline' })
vim.keymap.set('n', '<leader>td', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = 'Toggles Diagnostics', expr = true })

-- Quit
vim.keymap.set('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })

-- Chezmoi
vim.keymap.set('n', '<leader>cx', '<cmd>vnew | r ! chezmoi execute-template <#<cr>', { desc = 'Execute chezmoi template for preview' })

-- Miscellaneous
vim.keymap.set('n', '<leader>ds', "<cmd>lua require('neogen').generate()<CR>", { desc = 'Generate docstring' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page and center the cursor vertically' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page and center the cursor vertically' })
vim.keymap.set('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word under cursor' })
vim.keymap.set('n', 'J', 'mzJ`z', { desc = "Append the next line to the current but don't move the cursor" })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result and center the cursor vertically' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result and center the cursor vertically' })
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set({ 'n', 'v' }, '<leader>Y', '"+y$', { desc = 'Copy line to system clipboard' })
vim.keymap.set('n', '<leader>ay', '<cmd>%y+<CR>', { desc = 'Yank entire buffer to system clipboard' })
vim.keymap.set({ 'i', 'n', 'v' }, '<S-Insert>', '"+p', { desc = 'Paste from clipboard' })
vim.keymap.set('i', '<C-e>', '<esc>A', { desc = 'Put the cursor at the end of the line' })
