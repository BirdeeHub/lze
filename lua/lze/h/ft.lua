-- NOTE: simply an alias for lze.h.event for filetype
local event = require("lze.h.event")

local states = {}

local augroup = nil

local parse = function(value)
    return {
        id = value,
        event = "FileType",
        pattern = value,
        augroup = augroup,
    }
end

---@type lze.Handler
local M = {
    spec_field = "ft",
    lib = {
        parse = parse,
    },
    init = function()
        augroup = vim.api.nvim_create_augroup("lze_handler_ft", { clear = true })
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
        local ft = parse(ft_spec)
        ---@diagnostic disable-next-line: param-type-mismatch
        table.insert(plugin.event, ft)
    elseif type(ft_spec) == "table" then
        ---@param ft_spec_ string
        vim.iter(ft_spec):each(function(ft_spec_)
            local ft = parse(ft_spec_)
            ---@diagnostic disable-next-line: param-type-mismatch
            table.insert(plugin.event, ft)
        end)
    end
    states[plugin.name] = true
    event.add(plugin)
end

---@param name string
function M.before(name)
    if states[name] then
        event.before(name)
        states[name] = nil
    end
end

function M.cleanup()
    for name, _ in pairs(states) do
        event.before(name)
    end
    states = {}
    if augroup then
        vim.api.nvim_del_augroup_by_id(augroup)
    end
end

return M
