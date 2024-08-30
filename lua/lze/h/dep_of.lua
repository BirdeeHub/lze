---@type table<string, string[]>
local states = {}

-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local trigger_load = require("lze.c.loader").load

---@type lze.Handler
---@diagnostic disable-next-line: missing-fields
local M = {
    spec_field = "dep_of",
}

---@param plugin lze.Plugin
function M.add(plugin)
    local dep_of = plugin.dep_of

    -- I dont know why I need to tell luacheck
    -- that I actually loop over it in like 10 lines from now
    ---@type string[]
    --luacheck: no unused
    local needed_by = {}

    if type(dep_of) == "table" then
        ---@cast dep_of string[]
        needed_by = dep_of
    elseif type(dep_of) == "string" then
        needed_by = { dep_of }
    else
        return
    end
    for _, name in ipairs(needed_by) do
        if require("lze").query_state(name) == false then
            trigger_load(plugin.name)
        else
            if states[name] == nil then
                states[name] = {}
            end
            vim.list_extend(states[name], { plugin.name })
        end
    end
end

---@param name string
function M.before(name)
    if states[name] and require("lze").query_state(name) ~= nil then
        trigger_load(states[name])
        states[name] = nil
    end
end

return M
