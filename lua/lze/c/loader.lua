-- It turns out that its faster when you copy paste.
-- Would be nice to just define it once, but then you lose 10ms
---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_enabled(spec)
    local disabled = spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
    return not disabled
end

---@alias hook_key "before" | "after" | "beforeAll"

---@param hook_key hook_key | "load"
---@param pname string
---@param err any
local function mk_hook_err(hook_key, pname, err)
    vim.notify(
        "Failed to run '" .. hook_key .. "' hook for " .. pname .. ": " .. tostring(err or ""),
        vim.log.levels.ERROR,
        { title = "lze.spec." .. hook_key }
    )
end

---@param hook_key hook_key
---@param plugin lze.Plugin
local function hook(hook_key, plugin)
    if plugin[hook_key] then
        xpcall(
            plugin[hook_key],
            vim.schedule_wrap(function(err)
                mk_hook_err(hook_key, plugin.name, err)
            end),
            plugin
        )
    end
end

---@mod lze.loader
local M = {}

---@type table<string, lze.Plugin|false>
local state = {}

---@type lze.State
M.state = setmetatable({}, {
    __index = function(_, k)
        return vim.deepcopy(state[k])
    end,
    ---@param name string
    ---@return boolean?
    __call = function(_, name)
        return state[name] and true or state[name]
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
            state[pname] = false
            -- technically plugin spec before hooks can modify
            -- the plugin item provided to their own after hook
            -- This is not worth a deepcopy and should be considered a feature
            hook("before", plugin)
            require("lze.c.handler").run_before(pname)
            ---@type fun(name: string)
            local load_impl = plugin.load or vim.tbl_get(vim.g, "lze", "load") or vim.cmd.packadd
            local ok, err = pcall(load_impl, pname)
            if not ok and vim.tbl_get(vim.g, "lze", "verbose") ~= false then
                vim.schedule(function()
                    mk_hook_err("load", pname, err)
                end)
            end
            require("lze.c.handler").run_after(pname)
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
                if plugin == nil and vim.tbl_get(vim.g, "lze", "verbose") ~= false then
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
    return skipped
end

---@param plugins lze.Plugin[]
---@param verbose boolean
local function load_startup_plugins(plugins, verbose)
    local startups = {}
    for _, plugin in ipairs(plugins) do
        if not plugin.lazy then
            table.insert(startups, {
                name = plugin.name,
                -- NOTE: default priority is 50
                priority = plugin.priority or 50,
            })
        end
        hook("beforeAll", plugin)
    end
    table.sort(startups, function(a, b)
        return a.priority > b.priority
    end)
    for _, plugin in ipairs(startups) do
        local ok, v = pcall(M.load, plugin.name)
        if verbose and not ok then
            vim.schedule(function()
                vim.notify(
                    "Error occurred in '" .. plugin.name .. "'\nError text: " .. vim.inspect(v),
                    vim.log.levels.ERROR,
                    { title = "lze.load_startup_plugins" }
                )
            end)
        end
    end
end

---@param plugins lze.Plugin[]
---@return lze.Plugin[] final
---@return lze.Plugin[] disabled
local function add(plugins)
    local final = {}
    local duplicates = {}
    -- deepcopy after all handlers use modify
    -- now we have a copy the handlers can't change
    for _, v in ipairs(vim.deepcopy(plugins)) do
        local name = v.name
        if state[name] == nil then
            state[name] = v
            table.insert(final, v)
        elseif v.allow_again and not state[name] then
            state[name] = v
            table.insert(final, v)
        else
            table.insert(duplicates, v)
        end
    end
    -- Return copy of result, and names of duplicates
    -- This prevents handlers from changing state after the handler's modify hooks
    return vim.deepcopy(final), duplicates
end

---@type fun(spec: string|lze.Spec): lze.Plugin[]
function M.define(spec)
    local verbose = vim.tbl_get(vim.g, "lze", "verbose") ~= false
    if spec == nil or spec == {} then
        if verbose then
            vim.schedule(function()
                vim.notify("load has been called, but no spec was provided", vim.log.levels.ERROR, { title = "lze" })
            end)
        end
        return {}
    end
    if type(spec) == "string" then
        spec = { import = spec }
    end
    -- plugins that are parsed as disabled in this stage will not be included
    -- plugins that are parsed as enabled in this stage will remain in the queue
    -- until trigger_load is called AND the plugin is parsed as enabled at that time.
    local plugins = require("lze.c.parse")(spec, require("lze.c.handler").is_lazy, require("lze.c.handler").run_modify)
    -- add non-duplicates to state.
    local final_plugins, duplicates = add(plugins)
    -- calls handler adds with copies to prevent handlers messing with each other
    require("lze.c.handler").init(final_plugins)
    -- will call beforeAll of all plugin specs in the order passed in.
    -- will then call trigger_load on the non-lazy plugins
    -- in order of priority and the order passed in.
    load_startup_plugins(final_plugins, verbose)
    -- handlers can set up any of their own triggers for themselves here
    -- such as things like the event handler's DeferredUIEnter event
    require("lze.c.handler").run_post_def()
    if verbose then
        for _, v in ipairs(duplicates) do
            vim.schedule(function()
                vim.notify("attempted to add " .. v.name .. " twice", vim.log.levels.ERROR, { title = "lze" })
            end)
        end
    end
    return duplicates
end

return M
