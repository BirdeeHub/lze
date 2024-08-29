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
---Will return the names of the plugins that have been loaded before.
---@overload fun(plugin_names: string[]|string): string[]
lze.trigger_load = require("lze.c.loader").load

--- returns a COPY of the plugin from state, false for already loaded,
--- nil for never added. Useful in debug and possibly niche scenarios
---@type fun(name: string): false|lze.Plugin?
lze.query_state = require("lze.c.loader").query_state

---May be called as many times as desired if passing it a single spec.
---Will throw an warning if it contains a duplicate plugin
---and return the duplicate lze.Plugin objects.
---Also, priority field only works within a single load call.
---@overload fun(spec: lze.Spec)
---@overload fun(import: string)
---@return string[]
function lze.load(spec)
    if spec == nil or spec == {} then
        -- one of only 3 checks to verbose in this plugin,
        -- if handlers decide to call this function,
        -- the warnings controlled by vim.g.lze.verbose might get annoying.
        -- but they are very useful for debugging and for setting up your config
        -- for the first time. So we allow them to be configureable, but default to true
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
    --- @cast spec lze.Spec
    local final_plugins, duplicates = require("lze.c.loader").add(spec)

    -- calls add for all the handlers, each handler gets a copy, so that they
    -- cannot change the plugin object recieved by the other handlers
    -- outside of the modify step
    require("lze.c.handler").init(final_plugins)

    -- will call trigger_load on the non-lazy plugins
    require("lze.c.loader").load_startup_plugins(final_plugins)

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
