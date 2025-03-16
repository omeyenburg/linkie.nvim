-- linkie/init.lua

local Config = require 'linkie.config'
local Core = require 'linkie.core'
local Utils = require 'linkie.utils'

local M = {}

---@type Config
M.config = Config.defaults

---Dummy function before setup is called.
function M.open()
    vim.notify('linkie.nvim: Setup function has not been called!', vim.log.levels.ERROR)
end

---Set up the plugin with custom options
---@param opts? Config
function M.setup(opts)
    vim.notify("linke.nvim: setup", vim.log.levels.DEBUG)

    -- Setup config
    M.config = Config.setup(opts)

    -- Expose open command
    M.open = Core.open
    vim.api.nvim_create_user_command('LinkieOpen', Core.open, {})
end

return M
