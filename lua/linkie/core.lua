-- linkie/core.lua

local Treesitter = require("linkie.treesitter")

local M = {}

---Open link under cursor
---@param opts? table
function M.get(opts)
    return Treesitter.query_link()
end

---Open link under cursor
---@param opts? table
function M.open(opts)
    local type, value = M.get(opts)
    print(type)
    print(value)
end

return M
