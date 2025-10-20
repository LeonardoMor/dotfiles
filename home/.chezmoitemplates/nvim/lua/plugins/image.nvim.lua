local utils = require 'custom.utils'

local workspaces = vim
  .iter(vim.tbl_map(function(vault)
    return {
      vault.path,
    }
  end, utils.vaults))
  :flatten()
  :totable()

return {
  '3rd/image.nvim',
  ft = 'markdown',
  opts = {
    integrations = {
      markdown = {
        resolve_image_path = function(document_path, image_path, fallback)
          local working_dir = vim.fn.getcwd()
          local dir_name = vim.fn.expand '%:p:h'
          if vim.list_contains(workspaces, working_dir) then
            return vim.fs.normalize(dir_name .. '/attachments/' .. image_path)
          end
          return fallback(document_path, image_path)
        end,
      },
    },
  },
}
