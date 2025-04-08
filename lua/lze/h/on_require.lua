-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local trigger_load = require("lze.c.loader").load

---@type table<string, function>
local states = {}

-- NOTE: the thing that calls the load...
-- replacing the global require function

local old_require = require
local new_require = function(mod_path)
    local ok, value = pcall(old_require, mod_path)
    if ok then
        return value
    end
    local plugins = {}
    for name, has in pairs(states) do
        if has(mod_path) then
            table.insert(plugins, name)
        end
    end
    if next(plugins) ~= nil then
        trigger_load(plugins)
        return old_require(mod_path)
    end
    error(value)
end

-- NOTE: the handler for lze

---@class lze_plugin: lze.Plugin
---@field on_require? string[]|string

---@type lze.Handler
local M = {
    spec_field = "on_require",
    ---@param name string
    before = function(name)
        states[name] = nil
    end,
    init = function()
        _G.require = new_require
    end,
    cleanup = function()
        _G.require = old_require
        states = {}
    end,
}

---Adds a plugin to be lazy loaded upon requiring any submodule of provided mod paths
---@param plugin lze_plugin
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
            if vim.startswith(mod_path, v) then
                return true
            end
        end
        return false
    end
end

return M
