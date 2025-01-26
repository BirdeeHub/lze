---@type table<string, function>
local states = {}

local trigger_load = require("lze.c.loader").load

---@param mod_path string
---@return boolean
local function call(mod_path)
    local plugins = {}
    for _, has in pairs(states) do
        local plugin = has(mod_path)
        if plugin ~= nil then
            table.insert(plugins, plugin)
        end
    end
    if plugins ~= {} then
        trigger_load(plugins)
        return true
    end
    return false
end

-- NOTE: the thing that calls the load...
-- replacing the global require function with one that calls our call function

local oldrequire = require
require("_G").require = function(mod_path)
    local ok, value = pcall(oldrequire, mod_path)
    if ok then
        return value
    end
    package.loaded[mod_path] = nil
    if call(mod_path) == true then
        return oldrequire(mod_path)
    end
    error(value)
end

-- NOTE: the handler for lze

---@class lze_plugin: lze.Plugin
---@field on_require? string[]|string

---@type lze.Handler
---@diagnostic disable-next-line: missing-fields
local M = {
    spec_field = "on_require",
    ---@param name string
    before = function(name)
        states[name] = nil
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
    ---@return string|nil
    states[plugin.name] = function(mod_path)
        for _, v in ipairs(mod_paths) do
            if vim.startswith(mod_path, v) then
                return plugin.name
            end
        end
        return nil
    end
end

return M
