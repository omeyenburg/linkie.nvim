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
            (link_destination))
        ]]
    )

    for _, node, _ in query:iter_captures(root, 0, 0, -1) do
        local destination_node = node:next_named_sibling()
        if destination_node and get_node_text(node):lower() == label_text then
            return get_node_text(destination_node)
        end
    end

    return nil
end

---@return table anchors
local function get_anchors()
    local anchors = {}

    local parser = vim.treesitter.get_parser(0, 'markdown')
    local tree = parser:parse()[1]
    local root = tree:root()
    local query = vim.treesitter.query.parse('markdown', '(atx_heading (inline) @content)')

    for _, node, _ in query:iter_captures(root, 0, 0, -1) do
        local line = node:start()
        local heading = get_node_text(node)

        anchors[line] = heading:gsub(' ', '-'):lower()
    end

    return anchors
end

---@param markdown_link string
---@return "line"|"uri"|"path"|"none" type
---@return integer|string destination
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

    local beginning = markdown_link:sub(1, 1)

    if beginning == '#' then
        -- For Obsidian we also substitute spaces with hyphens
        -- to allow non-standard links with spaces.
        local anchor = markdown_link:sub(2):lower():gsub(' ', '-')
        local anchors = get_anchors()
        for line, a in pairs(anchors) do
            if anchor == a then
                return 'line', line
            end
        end

        return 'none', 0
    elseif Utils.validate_uri(markdown_link) then
        return 'uri', markdown_link
    else
        return 'path', markdown_link
    end
end

local M = {}

---@param node TSNode?
---@return "line"|"uri"|"email"|"path"|"none" type
---@return integer|string destination
function M.handle_markdown_node(node)
    -- We need to find the outer parent link node.
    -- Depending on the context, node could be one of a variety of unrelated child nodes:
    -- text, backslash_escape, character_reference, emphasis, etc.
    node = get_link_node(node)
    if node == nil then
        return 'none', 0
    end

    local node_type = node:type()

    -- Return autolinks early
    if node_type == 'email_autolink' then
        return 'email', strip_autolink(get_node_text(node))
    end
    if node_type == 'uri_autolink' or node_type == 'www_autolink' then
        return 'uri', strip_autolink(get_node_text(node))
    end

    local children = Utils.get_type_children(node)

    local markdown_link = get_markdown_link(children)
    if markdown_link == nil then
        -- For Obsidian we also cover links that are not
        -- possible in standard markdown, such as [[#section]]
        if children.link_text and get_node_text(children.link_text):sub(1, 1) == '#' then
            markdown_link = get_node_text(children.link_text)
        else
            return 'none', 0
        end
    end

    return get_markdown_destination(markdown_link)
end

return M
