---@mod lze

local lze = {}

if vim.fn.has("nvim-0.10.0") ~= 1 then
    error("lze requires Neovim >= 0.10.0")
end

local deferred_ui_enter = vim.schedule_wrap(function()
    if vim.v.exiting ~= vim.NIL then
        return
    end
    vim.g.lze_did_deferred_ui_enter = true
    vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
end)

---@type lze.Handler[]
lze.default_handlers = require("lze.h")

---THIS SHOULD BE CALLED BEFORE ANY CALLS TO lze.load ARE MADE
---Returns the cleared handlers
---@return lze.Handler[]
lze.clear_handlers = require("lze.c.handler").clear_handlers

---THIS SHOULD BE CALLED BEFORE ANY CALLS TO lze.load ARE MADE
---Returns the list of spec_field values added.
---@type fun(handlers: lze.Handler[]|lze.Handler|lze.HandlerSpec[]|lze.HandlerSpec): string[]
lze.register_handlers = require("lze.c.handler").register_handlers

---Trigger loading of the lze.Plugin loading hooks.
---Used by handlers to load plugins.
---Will return the names of the plugins that have been loaded before.
---@type fun(plugins: string| string[]): string[]
lze.trigger_load = require("lze.c.loader").load

---May be called as many times as desired if passing it a single spec.
---Will throw an warning if it contains a duplicate plugin
---and return the duplicate lze.Plugin objects.
---Also, priority field only works within a single load call.
---@overload fun(spec: lze.Spec)
---@overload fun(import: string)
---@return string[]
function lze.load(spec)
    if spec == nil or spec == {} then
        vim.schedule(function()
            vim.notify("load has been called, but no spec was provided", vim.log.levels.ERROR, { title = "lze" })
        end)
        return {}
    end
    if type(spec) == "string" then
        spec = { import = spec }
    end
    --- @cast spec lze.Spec
    local plugins = require("lze.c.spec").parse(spec)

    -- add to state before loading anything,
    -- so that we can call trigger_load always
    ---@type string[]
    local duplicates = {}
    local state = require("lze.c.state")
    for k, v in pairs(plugins) do
        if state.plugins[k] then
            table.insert(duplicates, k)
            vim.schedule(function()
                vim.notify("attempted to add " .. k .. " twice", vim.log.levels.ERROR, { title = "lze" })
            end)
        else
            state.plugins[k] = v
        end
    end

    -- calls handler add functions
    require("lze.c.handler").init(plugins)

    -- because this calls the handler's del functions,
    -- this should be ran after the handlers are given the plugin.
    -- even if the plugin isnt supposed to have been added to any of them
    require("lze.c.loader").load_startup_plugins(plugins)
    -- in addition, this allows even startup plugins to call
    -- require('lze').trigger_load('someplugin') safely

    if vim.v.vim_did_enter == 1 then
        deferred_ui_enter()
    elseif not vim.g.lze_did_create_deferred_ui_enter_autocmd then
        vim.api.nvim_create_autocmd("UIEnter", {
            once = true,
            callback = deferred_ui_enter,
        })
        vim.g.lze_did_create_deferred_ui_enter_autocmd = true
    end
    return duplicates
end

---Recieves the names of directories from a plugin's after directory
---that you wish to source files from.
---Will return a load function that can take a name, or list of names,
---and will load a plugin and its after directories.
---The function returned is a suitable substitute for the load field of a plugin spec.
---
---e.g. load_with_after_plugin will load the plugin names it is given, and their after/plugin dir
---
---local load_with_after_plugin = require('lze').make_load_with_after({ 'plugin' })
---load_with_after_plugin('some_plugin')
---@overload fun(dirs: string[]|string): fun(names: string|string[])
---It also optionally recieves a function that should load a plugin and return its path
---for if the plugin is not on the packpath, or return nil to load from the packpath as normal
---@overload fun(dirs: string[]|string, load: fun(name: string):string|nil): fun(names: string|string[])
function lze.make_load_with_after(dirs, load)
    dirs = (type(dirs) == "table" and dirs) or { dirs }
    local fromPackpath = function(name)
        for _, packpath in ipairs(vim.opt.packpath:get()) do
            local plugin_path = vim.fn.globpath(packpath, "pack/*/opt/" .. name, nil, true, true)
            if plugin_path[1] then
                return plugin_path[1]
            end
        end
        return nil
    end
    ---@param plugin_names string[]|string
    return function(plugin_names)
        local names
        if type(plugin_names) == "table" then
            names = plugin_names
        elseif type(plugin_names) == "string" then
            names = { plugin_names }
        else
            return
        end
        local to_source = {}
        for _, name in ipairs(names) do
            if type(name) == "string" then
                local path = (type(load) == "function" and load(name)) or nil
                if type(path) == "string" then
                    table.insert(to_source, { name = name, path = path })
                else
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local ok, err = pcall(vim.cmd, "packadd " .. name)
                    if ok then
                        table.insert(to_source, { name = name, path = path })
                    else
                        vim.notify(
                            '"packadd '
                                .. name
                                .. '" failed, and path provided by custom load function (if provided) was not a string\n'
                                .. err,
                            vim.log.levels.WARN,
                            { title = "lze.load_with_after" }
                        )
                    end
                end
            else
                vim.notify(
                    "plugin name was not a string and was instead of value:\n" .. vim.inspect(name),
                    vim.log.levels.WARN,
                    { title = "lze.load_with_after" }
                )
            end
        end
        for _, info in pairs(to_source) do
            local plugpath = info.path or fromPackpath(info.name)
            if type(plugpath) == "string" then
                local afterpath = plugpath .. "/after"
                for _, dir in ipairs(dirs) do
                    if vim.fn.isdirectory(afterpath) == 1 then
                        local plugin_dir = afterpath .. "/" .. dir
                        if vim.fn.isdirectory(plugin_dir) == 1 then
                            local files = vim.fn.glob(plugin_dir .. "/*", false, true)
                            for _, file in ipairs(files) do
                                if vim.fn.filereadable(file) == 1 then
                                    vim.cmd("source " .. file)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

---@type fun(plugins: string| string[]): string[]
---This function is HIGHLY inadviseable.
---however it might be useful in testing.
---Any issues using this function are not my fault.
lze.force_load = function(plugins)
    plugins = (type(plugins) == "string") and { plugins } or plugins
    ---@cast plugins string[]
    local state = require("lze.c.state")
    for _, plugin in ipairs(plugins) do
        state.loaded[plugin] = nil
    end
    return lze.trigger_load(plugins)
end

return lze
