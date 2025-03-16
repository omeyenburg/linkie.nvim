-- linkie/markdown.lua

local Utils = require 'linkie.utils'

---@param node TSNode
---@return string text
local function get_node_text(node)
    return vim.treesitter.get_node_text(node, 0)
end

---@param link string
---@return string stripped
local function strip_autolink(link)
    if link[1] == '<' then
        return link:sub(2, link:len() - 1)
    end
    return link
end

---@param node TSNode?
---@return TSNode? node
local function get_link_node(node)
    if node == nil then
        return nil
    end

    while
        not Utils.tbl_contains({
            'collapsed_reference_link', --  e.g.: [link_text][]
            'email_autolink', --            e.g.: <foo@bar.example.com> or foo@bar.example.com
            'full_reference_link', --       e.g.: [link_text][link_label]
            'image', --                     e.g.: ![image_description](link_destination) or ![image_description][link_label] or ![image_description]
            'inline_link', --               e.g.: [link_text](link_destination link_title) or [link_text]
            'link', --                      e.g.: [link_label](link_destination) or [link_label]
            'link_reference_definition', -- e.g.: [link_label]: link_destination link_title
            'shortcut_link', --             e.g.: [link_text]
            'uri_autolink', --              e.g.: <https://www.github.com> or https://www.github.com
            'www_autolink', --              e.g.: <www.github.com> www.github.com
        }, node:type())
    do
        node = node:parent()
        if node == nil then
            return nil
        end
    end

    return node
end

---@param node TSNode
---@return table<string, TSNode> children
local function get_type_children(node)
    local children = {}
    for child in node:iter_children() do
        local child_type = child:type()
        children[child_type] = child
        print(child:type())
    end

    return children
end

---@param children table<string, TSNode>
---@return string? markdown_link
local function get_markdown_link(children)
    if children.link_destination ~= nil then
        return get_node_text(children.link_destination)
    end

    local label, label_text
    if children.link_label ~= nil then
        label = children.link_label
        label_text = get_node_text(label):lower()
    elseif children.link_text ~= nil then
        label = children.link_text
        label_text = '[' .. get_node_text(label):lower() .. ']'
    elseif children.image_description ~= nil then
        label = children.image_description
        label_text = '[' .. get_node_text(label):lower() .. ']'
    else
        return nil
    end

    local parser = vim.treesitter.get_parser()
    local tree = parser:parse()[1]
    local root = tree:root()

    local query = vim.treesitter.query.parse(
        'markdown',
        [[
          (link_reference_definition
            (link_label) @label
            (link_destination) @destination)
        ]]
    )

    for id, node, _ in query:iter_captures(root, 0, 0, -1) do
        local capture_name = query.captures[id]
        local capture_text = vim.treesitter.get_node_text(node, 0):lower()

        if capture_name == 'label' then
            local destination_node = node:next_named_sibling()
            if destination_node and capture_text == label_text then
                return get_node_text(destination_node)
            end
        end
    end

    return nil
end

---@param markdown_link string
local function get_markdown_destination(markdown_link)
    --[[
    Example links:

    [#-chapter-1]               -> ## Chapter 1
    [#my-multi-word-header]     -> ### My Multi Word Header
    [foo]                       -> [Foo] -> case insensitive
    [/formatting-guide.md]      -> ./formatting-guide.md
    [/page/#conclusion]         -> ./page/ -> # Conclusion
    [https://en.wikipedia.org/] -> https://en.wikipedia.org/
    [file.///path]              -> /path

    ]]
end

local M = {}

---@param node TSNode?
function M.handle_markdown_node(node)
    -- We need to find the outer parent link node.
    -- Depending on the context, node could be one of a variety of unrelated child nodes:
    -- text, backslash_escape, character_reference, emphasis, etc.
    node = get_link_node(node)
    if node == nil then
        return nil
    end

    local node_type = node:type()

    -- Return autolinks early
    if node_type == 'email_autolink' then
        return {
            type = 'email',
            text = strip_autolink(get_node_text(node)),
        }
    end
    if node_type == 'uri_autolink' or node_type == 'www_autolink' then
        return {
            type = 'link',
            text = strip_autolink(get_node_text(node)),
        }
    end

    local children = get_type_children(node)

    local markdown_link = get_markdown_link(children)
    if markdown_link == nil then
        return nil
    end
    print('markdown link: ' .. markdown_link)

    get_markdown_destination(markdown_link)
end

return M
