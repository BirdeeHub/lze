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
    local final_plugins, duplicates = require("lze.c.loader").add(spec)

    require("lze.c.handler").init(final_plugins)

    require("lze.c.loader").load_startup_plugins(final_plugins)

    if vim.tbl_get(vim.g, "lze", "verbose") then
        for _, v in ipairs(duplicates) do
            vim.schedule(function()
                vim.notify("attempted to add " .. v .. " twice", vim.log.levels.ERROR, { title = "lze" })
            end)
        end
    end

    require("lze.c.handler").run_post_def()

    return duplicates
end

return lze
