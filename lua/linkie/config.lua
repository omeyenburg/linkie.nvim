-- linkie/config.lua

---@class Config
---@field link LinkConfig Command to open links
---@field file FileConfig Pattern to match links
---@field binary BinaryConfig Pattern to match links

---@class LinkConfig
---@field cmd string Command to open links. Guessed based on OS, if set to ""
---@field file_types string[] File types to open using the command. (instead of reading file)

---@class FileConfig
---@field method FileOpenMethod Mode to open file.
---@field file_uri boolean Whether to read uris starting with file:// in vim

---@class BinaryConfig
---@field run_without_confirm boolean Whether to run binary files with explicit confirmation

---@alias FileOpenMethod "buffer" | "split" | "vsplit" | "hsplit" | "tab"

local M = {
    defaults = {
        link = {
            cmd = '',
            file_types = { 'png' },
        },
        file = {
            method = 'buffer',
            file_uri = true,
        },
        binary = {
            run_without_confirm = false,
        },
    },
}

---Get the default command to open links based on the operating system.
---@return string cmd Default command to open links
local function get_default_cmd()
    local cmd

    if vim.fn.has 'win32' == 1 then
        cmd = 'start'
    elseif vim.fn.has 'mac' == 1 then
        cmd = 'open'
    else
        cmd = 'xdg-open'
    end

    return cmd
end

---Setup function to configure the plugin
---@param opts? Config
---@return Config The merged config
function M.setup(opts)
    opts = opts or {}

    -- Validate config
    if type(opts) ~= 'table' then
        vim.api.nvim_err_writeln('linkie.nvim: expected configuration to be table and not ' .. type(opts) .. '!')
        opts = M.defaults
    end

    -- Merge user options with default config
    local config = vim.tbl_deep_extend('force', M.defaults, opts or {})

    -- Default cmd based on OS if not set by user
    if config.link.cmd == '' then
        config.link.cmd = get_default_cmd()
    end

    -- Debug output
    -- vim.print(config)

    return config
end

return M
