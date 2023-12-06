local conf = require "plugins.configs.cmp"
table.insert(conf.sources, { name = "copilot", group_index = 2 })
require'cmp'.setup(conf)