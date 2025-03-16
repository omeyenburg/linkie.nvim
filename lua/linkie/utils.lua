-- linkie/utils.lua

local M = {}

---@param tbl table
---@param value any
function M.tbl_contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

return M
