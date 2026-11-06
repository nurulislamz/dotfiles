-- Disable netrw for neo-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.ai")
require("config.lazy")
require("config.keymaps")
require("clipboard").setup()
