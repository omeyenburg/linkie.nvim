-- linkie/treesitter.lua

local Markdown = require 'linkie.markdown'
local Utils = require 'linkie.utils'

-- -- common: link, uri, url, http_import
-- local link_types = {
--     'autolink',
--     'http_import',
--     'link_destination',
--     'link_target',
--     'link_text',
--     'md_link',
--     'uri',
--     'uri_expression',
--     'url',
--     'web_link',
-- }
--
-- -- common: PATH, path, file
-- local path_types = {
--     'PATH',
--     'absolute_path',
--     'asset_path',
--     'file',
--     'file_path',
--     'filename',
--     'import_path',
--     'include_path',
--     'module_path',
--     'path',
--     'prim_path',
--     'relative_path',
-- }
--
-- -- common: string, str_, char_literal, character_literal, char_sequence, documentation, quote, heredoc, escape_sequence, text, word
-- local string_types = {
--     'ansi_c_string',
--     'attribute_value',
--     'char_literal',
--     'char_sequence',
--     'character_literal',
--     'data_string',
--     'docstring',
--     'documentation',
--     'double_quote_scalar',
--     'escape_sequence',
--     'heredoc',
--     'indented_string_expression',
--     'info_string',
--     'interpolated_string_expression',
--     'interpreted_string_literal',
--     'line_str_text',
--     'line_string_literal',
--     'literal_text',
--     'long_str_lit',
--     'multi_line_str_text',
--     'multi_line_string_literal',
--     'quote',
--     'quoted_word',
--     'raw_str_end_part',
--     'raw_string',
--     'raw_string_literal',
--     'single_quote_scalar',
--     'str_escaped_char',
--     'str_lit',
--     'string',
--     'string_constant_expr',
--     'string_content',
--     'string_expression',
--     'string_fragment',
--     'string_literal',
--     'string_scalar',
--     'string_token',
--     'string_value',
--     'system_lib_string',
--     'template_string',
--     'template_string_expression',
--     'text',
--     'text_literal',
--     'unquoted_string',
--     'val_string',
--     'verbatim_string',
--     'verbatim_string_literal',
--     'wide_string_literal',
--     'word',
-- }

local M = {}

local function get_filetype()
    return vim.treesitter.get_parser(0):lang()
end

-- Will throw an error if tree sitter is not found
---@return TSNode?
local function get_cursor_node()
    return require('nvim-treesitter.ts_utils').get_node_at_cursor()
end

---@param node TSNode
---@return "uri"|"path"|"string"|"none" group
local function get_node_group(node)
    local node_type = node:type():lower()

    local groups = {
        uri = {
            'link',
            'uri',
            'url',
            'http_import',
        },
        path = {
            'path',
            'file',
        },
        string = {
            'string',
            'str_',
            'char',
            'documentation',
            'quote',
            'heredoc',
            'text',
            'word',
        },
    }

    for group, group_types in pairs(groups) do
        for _, group_type in ipairs(group_types) do
            if node_type:find(group_type) ~= nil then
                return group
            end
        end
    end

    return 'none'
end

---@return "line"|"uri"|"email"|"path"|"string"|"none" type
---@return integer|string destination
function M.query_link()
    local success, node = pcall(get_cursor_node)
    if not (success and node) then
        return 'none', 0
    end

    local filetype = get_filetype()
    local subfiletype
    if filetype == 'markdown' then
        local group, value = Markdown.handle_markdown_node(node)
        if group ~= 'none' then
            return group, value
        end

        subfiletype = Markdown.get_code_language(node)
    end

    local group = get_node_group(node)
    while group == 'none' and node ~= nil do
        group = get_node_group(node)
        node = node:parent()
    end

    if node == nil then
        return 'none', 0
    end

    -- If we hover on a quote of a string, this might be separate from it's content.
    -- Usually languages use string_content or string_fragment for the content of the string.
    local parent = node:parent()
    if group == 'string' and parent ~= nil and get_node_group(parent) == 'string' then
        local children = Utils.ts_get_children(parent)

        -- Use string_content or string_fragment if possible.
        -- NOTE: Maybe its safer to just try to strip of any quotes/string delimiters from the parent?
        if filetype == 'markdown' and (subfiletype == 'sh' or subfiletype == 'bash') then
            -- sh and bash use string_content nodes that exclude variables.
            node = parent
        elseif children.string_content then
            node = children.string_content
        elseif children.string_fragment then
            node = children.string_fragment
        else
            node = parent
        end
    end

    local node_text = vim.treesitter.get_node_text(node, 0)
    return group, node_text
end

return M
