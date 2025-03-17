-- test/init.lua
-- vim.opt.runtimepath:append(".")  -- Add current project to runtime path
-- vim.cmd("runtime plugin/plenary.vim")  -- Load plenary if you're using it

-- Add the plugin and test directories to runtimepath
vim.opt.runtimepath:append(vim.fn.expand("~/git/linkie.nvim"))
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"))
