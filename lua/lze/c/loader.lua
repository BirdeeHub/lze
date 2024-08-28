---@mod lze.loader

local state = {}

local M = {}

local DEFAULT_PRIORITY = 50

---@param plugins lze.Plugin[]
local function run_before_all(plugins)
    for _, plugin in ipairs(plugins) do
        if plugin.beforeAll then
            xpcall(
                plugin.beforeAll,
                vim.schedule_wrap(function(err)
                    vim.notify(
                        "Failed to run 'beforeAll' for " .. plugin.name .. ": " .. tostring(err or ""),
                        vim.log.levels.ERROR
                    )
                end),
                plugin
            )
        end
    end
end

---@param plugin lze.Plugin
local function get_priority(plugin)
    return plugin.priority or DEFAULT_PRIORITY
end

---@param plugins lze.Plugin[]
---@return lze.Plugin[]
local function get_eager_plugins(plugins)
    ---@type lze.Plugin[]
    local result = {}
    for _, plugin in ipairs(plugins) do
        if plugin.lazy == true then
            table.insert(result, plugin)
        end
    end
    table.sort(result, function(a, b)
        ---@cast a lze.Plugin
        ---@cast b lze.Plugin
        return get_priority(a) > get_priority(b)
    end)
    return result
end

--- Loads startup plugins, removing loaded plugins from the table
---@param plugins lze.Plugin[]
function M.load_startup_plugins(plugins)
    run_before_all(plugins)
    -- NOTE: looping and calling 1 at a time
    -- to map plugins to plugin.name
    -- is faster than mapping first,
    -- then passing them all to load
    -- as we only have to iterate the table once
    ---@param plugin lze.Plugin
    for _, plugin in ipairs(get_eager_plugins(plugins)) do
        M.load(plugin.name)
    end
end

---@alias hook_key "before" | "after"

---@param hook_key hook_key
---@param plugin lze.Plugin
local function hook(hook_key, plugin)
    if plugin[hook_key] then
        xpcall(
            plugin[hook_key],
            vim.schedule_wrap(function(err)
                vim.notify(
                    "Failed to run '" .. hook_key .. "' hook for " .. plugin.name .. ": " .. tostring(err or ""),
                    vim.log.levels.ERROR
                )
            end),
            plugin
        )
    end
end

---@type table<string, lze.Plugin|false>
state.plugins = {}

---@param spec lze.Spec
---@return table
---@return string[]
function M.add(spec)
    ---@type string[]
    local duplicates = {}
    local final = {}
    local plugins = require("lze.c.spec").parse(spec)
    for _, v in ipairs(plugins) do
        if state.plugins[v.name] == nil then
            state.plugins[v.name] = v
            table.insert(final, v)
        elseif v.allow_again and not state.plugins[v.name] then
            state.plugins[v.name] = v
            table.insert(final, v)
        else
            table.insert(duplicates, v.name)
        end
    end
    return vim.deepcopy(final), duplicates
end

local function check_enabled(plugin)
    if plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled()) then
        return false
    end
    return true
end

---@param plugin lze.Plugin
local function _load(plugin)
    require("lze.c.handler").run_before(plugin.name)
    ---@type fun(name: string) | nil
    local load_impl = plugin.load or vim.tbl_get(vim.g, "lze", "load")
    if load_impl then
        load_impl(plugin.name)
    else
        vim.cmd.packadd(plugin.name)
    end
    require("lze.c.handler").run_after(plugin.name)
end

---@overload fun(plugin_names: string[]|string): string[]
function M.load(plugin_names)
    plugin_names = (type(plugin_names) == "string") and { plugin_names } or plugin_names
    ---@type string[]
    local skipped = {}
    ---@cast plugin_names string[]
    for _, pname in ipairs(plugin_names) do
        local plugin = state.plugins[pname]
        if plugin and check_enabled(plugin) then
            state.plugins[pname] = false
            hook("before", plugin)
            _load(plugin)
            hook("after", plugin)
        else
            if type(pname) ~= "string" then
                vim.notify(
                    "Invalid plugin name recieved: " .. vim.inspect(pname),
                    vim.log.levels.ERROR,
                    { title = "lze" }
                )
            else
                table.insert(skipped, pname)
                if vim.tbl_get(vim.g, "lze", "verbose") then
                    if plugin == nil then
                        vim.schedule(function()
                            vim.notify("Plugin " .. pname .. " not found", vim.log.levels.ERROR, { title = "lze" })
                        end)
                    end
                end
            end
        end
    end
    return skipped
end

return M
