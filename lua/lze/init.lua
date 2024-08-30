---@mod lze

local lze = {}

if vim.fn.has("nvim-0.10.0") ~= 1 then
    error("lze requires Neovim >= 0.10.0")
end

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
---Will return the names of the plugins that were skipped,
---either because they were already loaded or because they
---were never added to the queue.
---@overload fun(plugin_names: string[]|string): string[]
lze.trigger_load = require("lze.c.loader").load

---returns a COPY of the plugin from state,
---or false for already loaded (or being loaded currently),
---nil for never added. Useful in debug and possibly niche scenarios
---@type fun(name: string): false|lze.Plugin?
lze.query_state = require("lze.c.loader").query_state

---May be called as many times as desired.
---Will return the duplicate lze.Plugin objects.
---Priority spec field only affects order for
---non-lazy plugins within a single load call.
---@overload fun(spec: lze.Spec)
---@overload fun(import: string)
---@return string[]
function lze.load(spec)
    if spec == nil or spec == {} then
        -- one of only 3 checks to verbose in this plugin.
        -- By default, warn if spec was empty
        if vim.tbl_get(vim.g, "lze", "verbose") ~= false then
            vim.schedule(function()
                vim.notify("load has been called, but no spec was provided", vim.log.levels.ERROR, { title = "lze" })
            end)
        end
        return {}
    end
    if type(spec) == "string" then
        spec = { import = spec }
    end

    -- call parse, which deepcopies after ALL ACTIVE HANDLERS FOR THAT ITEM use modify
    -- add non-duplicates to state. Return copy of result, and names of duplicates
    -- This prevents handlers from changing state after the handler's modify hooks

    -- plugins that are parsed as disabled in this stage will not be included

    -- plugins that are parsed as enabled in this stage will remain in the queue
    -- until trigger_load is called AND the plugin is parsed as enabled at that time.
    --- @cast spec lze.Spec
    local final_plugins, duplicates = require("lze.c.loader").add(spec)

    -- calls add for all the handlers, each handler gets a copy, so that they
    -- cannot change the plugin object recieved by the other handlers
    -- outside of the modify step
    require("lze.c.handler").init(final_plugins)

    -- will call beforeAll of all plugin specs in the order passed in.
    -- will then call trigger_load on the non-lazy plugins
    -- the order in which it calls trigger_load depends
    -- on priority value, OR the order passed into load
    require("lze.c.loader").load_startup_plugins(final_plugins)

    -- by default, warn on duplicate entries.
    if vim.tbl_get(vim.g, "lze", "verbose") ~= false then
        for _, v in ipairs(duplicates) do
            vim.schedule(function()
                vim.notify("attempted to add " .. v .. " twice", vim.log.levels.ERROR, { title = "lze" })
            end)
        end
    end

    -- handlers can set up any of their own triggers for themselves here
    -- such as things like the event handler's DeferredUIEnter event
    require("lze.c.handler").run_post_def()

    return duplicates
end

return lze
