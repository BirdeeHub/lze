---@param spec lze.Plugin
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

-- NOTE: must be userdata rather than table
-- otherwise __len never gets called
-- because tables cache their length
-- but this only works with luajit
-- so if you change to non-luajit,
-- just make it a table and accept that # will always return 0.
local proxy = newproxy and newproxy(true) or {}
local proxy_mt = getmetatable(proxy)
proxy_mt.__index = function(_, k)
    return vim.deepcopy(state[k])
end
proxy_mt.__tostring = function()
    return vim.inspect(state)
end
proxy_mt.__len = function(_)
    local count = 0
    for _, v in pairs(state) do
        if v then
            count = count + 1
        end
    end
    return count
end
---@param name string
---@return boolean?
proxy_mt.__call = function(_, name)
    ---@diagnostic disable-next-line: return-type-mismatch
    return state[name] and true or state[name]
end
proxy_mt.__unm = function(_)
    return vim.deepcopy(state)
end
proxy_mt.__newindex = function(_, k, v)
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
end

---@type lze.State
---@diagnostic disable-next-line: assign-type-mismatch
M.state = proxy

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
            ---@type fun(name: string)
            local load_impl = plugin.load or vim.tbl_get(vim.g, "lze", "load") or vim.cmd.packadd
            hook("before", plugin)
            require("lze.c.handler").run_before(pname)
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

local delayed = {}
---@param f fun()
local function delay(f)
    table.insert(delayed, f)
end
local function run_delayed()
    local torun = delayed
    delayed = {}
    for _, f in ipairs(torun) do
        local ok, err = pcall(f)
        if not ok then
            vim.schedule(function()
                vim.notify(
                    "Error occurred in deferred function returned by handler modify or add hook \nError text: " .. err,
                    vim.log.levels.ERROR,
                    { title = "lze.handler_deferred_fn" }
                )
            end)
        end
    end
end

---@param plugins lze.Plugin[]
---@param verbose boolean
---@return lze.Plugin[] final
---@return lze.Plugin[] disabled
local function add(plugins, verbose)
    local final = {}
    local duplicates = {}
    for _, v in ipairs(plugins) do
        local plugin = require("lze.c.handler").run_modify(v, delay)
        assert(
            type(plugin) == "table" and type(plugin.name) == "string",
            "handler modify hook must return a valid plugin"
        )
        if plugin.lazy == nil then
            plugin.lazy = require("lze.c.handler").is_lazy(plugin)
        end
        local p = vim.deepcopy(plugin)
        if is_enabled(plugin) then
            -- deepcopy after all handlers use modify
            -- now we have a copy the handlers can't change
            local name = p.name
            if state[name] == nil then
                state[name] = p
                table.insert(final, p)
            elseif v.allow_again and not state[name] then
                state[name] = p
                table.insert(final, p)
            else
                table.insert(duplicates, p)
                if verbose then
                    vim.schedule(function()
                        vim.notify("attempted to add " .. p.name .. " twice", vim.log.levels.ERROR, { title = "lze" })
                    end)
                end
            end
        end
    end
    -- Return copy of result, and names of duplicates
    -- This prevents handlers from changing state after the handler's modify hooks
    return vim.deepcopy(final), duplicates
end

---@param plugins lze.Plugin[]
---@param verbose boolean
local function load_startup_plugins(plugins, verbose)
    local startups = {}
    local default_priority = vim.tbl_get(vim.g, "lze", "default_priority") or 50
    for _, plugin in ipairs(plugins) do
        if not plugin.lazy then
            table.insert(startups, {
                name = plugin.name,
                priority = plugin.priority or default_priority,
            })
        end
        hook("beforeAll", plugin)
    end
    run_delayed()
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

---@type fun(spec: string|lze.Spec): lze.Plugin[]
function M.define(spec)
    local verbose = vim.tbl_get(vim.g, "lze", "verbose") ~= false
    if type(spec) == "string" then
        spec = { import = spec }
    elseif spec == nil or type(spec) ~= "table" then
        if verbose then
            vim.schedule(function()
                vim.notify(
                    "load was called with no arguments or invalid spec. Called with: " .. vim.inspect(spec),
                    vim.log.levels.ERROR,
                    { title = "lze" }
                )
            end)
        end
        return {}
    end
    -- plugins that are parsed as disabled in this stage will not be included
    -- plugins that are parsed as enabled in this stage will remain in the queue
    -- until trigger_load is called AND the plugin is parsed as enabled at that time.
    local plugins = require("lze.c.parse")(spec)
    -- add non-duplicates to state.
    local final_plugins, duplicates = add(plugins, verbose)
    -- calls handler adds with copies to prevent handlers messing with each other
    require("lze.c.handler").init(final_plugins, delay)
    -- will call beforeAll of all plugin specs in the order passed in.
    -- will then call trigger_load on the non-lazy plugins
    -- in order of priority and the order passed in.
    load_startup_plugins(final_plugins, verbose)
    -- handlers can set up any of their own triggers for themselves here
    -- such as things like the event handler's DeferredUIEnter event
    require("lze.c.handler").run_post_def()
    return duplicates
end

return M
