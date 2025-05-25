-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local trigger_load = require("lze.c.loader").load

---@type table<string, function>
local states = {}

local new_loader = function(mod_path)
    local plugins = {}
    for name, has in pairs(states) do
        if has(mod_path) then
            table.insert(plugins, name)
        end
    end
    if next(plugins) ~= nil then
        return function()
            package.loaded[mod_path] = nil
            trigger_load(plugins)
            return require(mod_path)
        end
    end
    return "\n\tlze.on_require: no plugin registered to load on require of '" .. tostring(mod_path) .. "'"
end

---@type lze.Handler
local M = {
    spec_field = "on_require",
    ---@param name string
    before = function(name)
        states[name] = nil
    end,
    init = function()
        table.insert(package.loaders or package.searchers, new_loader)
    end,
    cleanup = function()
        for i, v in ipairs(package.loaders or package.searchers) do
            if v == new_loader then
                table.remove(package.loaders or package.searchers, i)
            end
        end
        states = {}
    end,
}

---Adds a plugin to be lazy loaded upon requiring any submodule of provided mod paths
---@param plugin lze.Plugin
function M.add(plugin)
    local on_req = plugin.on_require

    -- I dont know why I need to tell luacheck
    -- that I actually stick it in a function where I
    -- loop over it later in like 10 lines from now
    ---@type string[]
    --luacheck: no unused
    local mod_paths = {}

    if type(on_req) == "table" then
        ---@cast on_req string[]
        mod_paths = on_req
    elseif type(on_req) == "string" then
        mod_paths = { on_req }
    else
        return
    end
    ---@param mod_path string
    ---@return boolean
    states[plugin.name] = function(mod_path)
        for _, v in ipairs(mod_paths) do
            if mod_path and mod_path:sub(1, #v) == v then
                return true
            end
        end
        return false
    end
end

return M
