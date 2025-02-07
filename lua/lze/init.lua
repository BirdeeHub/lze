---@mod lze

local lze = {}

if vim.fn.has("nvim-0.10.0") ~= 1 then
    error("lze requires Neovim >= 0.10.0")
end

---registers a handler with lze to add new spec fields
---Returns the list of spec_field values added.
---THIS SHOULD BE CALLED BEFORE ANY CALLS TO lze.load ARE MADE
---@type fun(handlers: lze.Handler[]|lze.Handler|lze.HandlerSpec[]|lze.HandlerSpec): string[]
lze.register_handlers = require("lze.c.handler").register_handlers

---Returns the cleared handlers
---THIS SHOULD BE CALLED BEFORE ANY CALLS TO lze.load ARE MADE
---@type fun():lze.Handler[]
lze.clear_handlers = require("lze.c.handler").clear_handlers

---Returns the cleared handlers
---THIS SHOULD BE CALLED BEFORE ANY CALLS TO lze.load ARE MADE
---@type fun(handler_names: string|string[]):lze.Handler[]
lze.remove_handlers = require("lze.c.handler").remove_handlers

---Trigger loading of the lze.Plugin loading hooks.
---Used by handlers to load plugins.
---Will return the names of the plugins that were skipped,
---either because they were already loaded or because they
---were never added to the queue.
---@type fun(plugin_names: string[]|string): string[]
lze.trigger_load = require("lze.c.loader").load

---May be called as many times as desired.
---Will return the names of duplicate lze.Plugin objects.
---Priority spec field only affects order for
---non-lazy plugins within a single load call.
---accepts a list of lze.Spec or a single lze.Spec
---may accept a module name to require instead
---@type fun(spec: string|lze.Spec): string[]
lze.load = require("lze.c.loader").define

--- `false` for already loaded (or being loaded currently),
--- `nil` for never added. READ ONLY TABLE
--- Function access only checks; table access returns a COPY.
--- unary minus is defined as vim.deepcopy of the actual state table
--- local snapshot = -require('lze').state
--- whereas the following will return this object, and thus remain up to date
--- local state = require('lze').state
---@alias lze.State
--- | fun(name: string): boolean? # Faster, returns `boolean?`.
--- | table<string, lze.Plugin|false?> # Access returns COPY of state for that plugin name.
---@type lze.State
lze.state = require("lze.c.loader").state

return lze
