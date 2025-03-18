-- linkie/utils.lua

local M = {}

-- Check whether a table contains a value
---@param tbl table
---@param value any
---@return boolean
function M.tbl_contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Split a uri on the first colon into scheme and content.
---@param uri string
---@return string scheme
---@return string content
function M.split_uri(uri)
    local i, _ = uri:find ':'
    if i == nil then
        return '', ''
    end

    local scheme = uri:sub(1, i - 1)
    local content = uri:sub(i + 1, uri:len())

    return scheme, content
end

-- Check whether a string is a valid URI.
-- This does not cover all edge cases and allow malformed URIs.
-- https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax
---@param uri string
---@return boolean is_uri
function M.validate_uri(uri)
    local scheme, content = M.split_uri(uri)
    if scheme == '' or content == '' then
        return false
    end

    if scheme:match '^[A-Za-z][A-Za-z0-9%+%-%.]*$' == nil then
        return false
    end

    if content:find '%s' ~= nil then
        return false
    end

    local first_question_mark = content:find('?', 1, true)
    if first_question_mark then
        local second_question_mark = content:find('?', first_question_mark + 1, true)
        if second_question_mark ~= nil then
            return false
        end
    else
        first_question_mark = 0
    end

    local first_hash = content:find('#', 1, true)
    if first_hash then
        if first_hash < first_question_mark then
            return false
        end

        local second_hash = content:find('#', first_hash + 1, true)
        if second_hash ~= nil then
            return false
        end
    end

    -- Check for unclosed brackets
    local symbol_stack = {}
    function symbol_stack:pop()
        table.remove(symbol_stack, #symbol_stack)
    end
    function symbol_stack:top()
        return symbol_stack[#symbol_stack]
    end
    for i = 1, #content do
        local symbol = content:sub(i, i)

        if symbol == '[' or symbol == '(' then
            table.insert(symbol_stack, symbol)
        elseif symbol == ']' then
            if symbol_stack:top() == '[' then
                symbol_stack:pop()
            else
                return false
            end
        elseif symbol == ')' then
            if symbol_stack:top() == '(' then
                symbol_stack:pop()
            else
                return false
            end
        end
    end
    if #symbol_stack ~= 0 then
        return false
    end

    -- Missing authority is allowed
    local _, authority_end = content:find '^//[^/?#%s]*'
    if authority_end == nil then
        authority_end = 0
    end

    local path = content:sub(authority_end + 1)
    if path == nil or path == '' then
        if authority_end < 3 then
            return false
        end

        return true
    end

    if authority_end > 2 and path:sub(1, 1) ~= '/' then
        return false
    end

    if authority_end == 0 and scheme:len() == 1 then
        return false
    end

    return true
end

---@param node TSNode
---@return table<string, TSNode> children
function M.ts_get_children(node)
    local children = {}

    for child in node:iter_children() do
        local child_type = child:type()
        children[child_type] = child
    end

    return children
end

---@param node TSNode
---@param name string
---@return TSNode? child
function M.ts_get_named_child(node, name)
    for child in node:iter_children() do
        if child:type() == name then
            return child
        end
    end

    return nil
end

---@param node TSNode
---@return string text
function M.ts_get_node_text(node)
    return vim.treesitter.get_node_text(node, 0)
end

return M
