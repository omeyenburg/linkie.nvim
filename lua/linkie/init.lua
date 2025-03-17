-- linkie/init.lua

local Config = require 'linkie.config'
local Core = require 'linkie.core'

-- Dummy function before setup is called.
local function dummy()
    vim.notify('linkie.nvim: Setup function has not been called!', vim.log.levels.ERROR)
end
local M = { get = dummy, open = dummy }

---@type Config
M.config = Config.defaults

---Set up the plugin with custom options
---@param opts? Config
function M.setup(opts)
    -- Setup config
    M.config = Config.setup(opts)

    -- Expose open command
    M.get = Core.get
    M.open = Core.open
    vim.api.nvim_create_user_command('LinkieOpen', Core.open, {})

    -- Overwrite setup to handle multiple setup calls
    M.setup = Config.setup
end

return M
