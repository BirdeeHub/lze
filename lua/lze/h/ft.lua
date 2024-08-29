-- NOTE: simply an alias for lze.h.event for filetype
local event = require("lze.h.event")

---@class lze.FtHandler: lze.Handler
---@field parse fun(spec: lze.EventSpec): lze.Event

---@type lze.FtHandler
local M = {
    pending = {},
    spec_field = "ft",
    ---@param value string
    ---@return lze.Event
    parse = function(value)
        return {
            id = value,
            event = "FileType",
            pattern = value,
        }
    end,
}

---@param plugin lze.Plugin
function M.add(plugin)
    local ft_spec = plugin.ft
    if not ft_spec then
        return
    end
    ---@type lze.Event[]
    plugin.event = {}
    if type(ft_spec) == "string" then
        local ft = M.parse(ft_spec)
        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(plugin.event, ft)
    elseif type(ft_spec) == "table" then
        ---@param ft_spec_ string
        vim.iter(ft_spec):each(function(ft_spec_)
            local ft = M.parse(ft_spec_)
            ---@diagnostic disable-next-line: param-type-mismatch
            table.insert(plugin.event, ft)
        end)
    end
    event.add(plugin)
end

---@param name string
function M.before(name)
    event.before(name)
end

return M
