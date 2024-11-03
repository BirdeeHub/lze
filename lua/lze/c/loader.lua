---@param plugin lze.Plugin
local function get_priority(plugin)
    -- NOTE: default priority is 50
    return plugin.priority or 50
end

---@param plugins lze.Plugin[]
---@return lze.Plugin[]
local function get_eager_plugins(plugins)
    ---@type lze.Plugin[]
    local result = {}
    for _, plugin in ipairs(plugins) do
        if not plugin.lazy then
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

---@alias hook_key "before" | "after" | "beforeAll"

---@param hook_key hook_key
---@param plugin lze.Plugin
local function hook(hook_key, plugin)
    if plugin[hook_key] then
        xpcall(
            plugin[hook_key],
            vim.schedule_wrap(function(err)
                vim.notify(
                    "Failed to run '" .. hook_key .. "' hook for " .. plugin.name .. ": " .. tostring(err or ""),
                    vim.log.levels.ERROR,
                    { title = "lze.spec." .. hook_key }
                )
            end),
            plugin
        )
    end
end

-- It turns out that its faster when you copy paste
-- Would be nice to just define it
-- once, but then you lose 10ms
---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_enabled(spec)
    local disabled = spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
    return not disabled
end

---@param plugin lze.Plugin
local function _load(plugin)
    require("lze.c.handler").run_before(plugin.name)
    ---@type fun(name: string)
    local load_impl = plugin.load or vim.tbl_get(vim.g, "lze", "load") or vim.cmd.packadd
    load_impl(plugin.name)
    require("lze.c.handler").run_after(plugin.name)
end

---@mod lze.loader
local M = {}

--- Loads startup plugins, removing loaded plugins from the table
---@param plugins lze.Plugin[]
function M.load_startup_plugins(plugins)
    for _, plugin in ipairs(plugins) do
        hook("beforeAll", plugin)
    end
    -- NOTE:
    -- looping and calling 1 at a time
    -- to map plugins to plugin.name
    -- is faster than mapping to just names first,
    -- then passing them all to load
    -- as we only have to iterate the list once
    for _, plugin in ipairs(get_eager_plugins(plugins)) do
        M.load(plugin.name)
    end
end

---@type table<string, lze.Plugin|false>
local state = {}

---@param spec lze.Spec
---@return lze.Plugin[] final
---@return string[] disabled
function M.add(spec)
    ---@type string[]
    local duplicates = {}
    local final = {}
    local plugins = require("lze.c.spec").parse(spec)
    for _, v in ipairs(plugins) do
        if state[v.name] == nil then
            state[v.name] = v
            table.insert(final, v)
        elseif v.allow_again and not state[v.name] then
            state[v.name] = v
            table.insert(final, v)
        else
            table.insert(duplicates, v.name)
        end
    end
    return vim.deepcopy(final), duplicates
end

---@param name string
---@return false|lze.Plugin?
function M.query_state(name)
    vim.notify(
        [[Being depreciated for equivalent `require('lze').state[name]` and the new,
        faster but less informative, `require('lze').state(name):boolean?`]],
        vim.log.levels.WARN,
        { title = "lze.state" }
    )
    return vim.deepcopy(state[name])
end

---@type lze.State
M.state = setmetatable({}, {
    __index = function(_, k)
        return vim.deepcopy(state[k])
    end,
    ---@param name string
    ---@return boolean?
    __call = function(_, name)
        if not state[name] then
            return state[name]
        else
            return true
        end
    end,
    __unm = function(_)
        return vim.deepcopy(state)
    end,
    __newindex = function(_, k, v)
        vim.schedule(function()
            vim.notify(
                "Arbitrary modification of lze's internal state is not allowed outside of an lze.Handler's modify hook.\n"
                    .. "value: '"
                    .. vim.inspect(v)
                    .. "' NOT added to require('lze').state."
                    .. tostring(k),
                vim.log.levels.ERROR,
                { title = "lze.state" }
            )
        end)
    end,
    __len = function() -- not that performant, but, may as well
        local count = 0
        for _ in pairs(state) do
            count = count + 1
        end
        return count
    end,
})

---@type fun(plugin_names: string[]|string): string[]
function M.load(plugin_names)
    plugin_names = (type(plugin_names) == "string") and { plugin_names } or plugin_names
    ---@type string[]
    local skipped = {}
    ---@cast plugin_names string[]
    for _, pname in ipairs(plugin_names) do
        local plugin = state[pname]
        if plugin and is_enabled(plugin) then
            -- NOTE:
            -- technically SPEC before hooks can modify the plugin item
            -- that is ran by following hooks by modifying their argument,
            -- but an extra deepcopy for each
            -- is likely not worth the performance penalty
            -- as they can only modify the plugin item they are within anyway
            state[pname] = false
            hook("before", plugin)
            _load(plugin)
            hook("after", plugin)
        else
            if type(pname) ~= "string" then
                vim.notify(
                    "Invalid plugin name recieved: " .. vim.inspect(pname),
                    vim.log.levels.ERROR,
                    { title = "lze.trigger_load" }
                )
            else
                table.insert(skipped, pname)
                if vim.tbl_get(vim.g, "lze", "verbose") ~= false then
                    if plugin == nil then
                        vim.schedule(function()
                            vim.notify(
                                "Plugin " .. pname .. " not found",
                                vim.log.levels.ERROR,
                                { title = "lze.trigger_load" }
                            )
                        end)
                    end
                end
            end
        end
    end
    return skipped
end

return M
