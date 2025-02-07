local M = {}

---@type lze.Handler[]
local handlers = require("lze.h")

---Removes and returns all handlers
---@return lze.Handler[]
function M.clear_handlers()
    local old_handlers = handlers
    handlers = {}
    return old_handlers
end

---Removes and returns the named handlers (named by spec_field)
---@param names string|string[]
---@return lze.Handler[]
function M.remove_handlers(names)
    ---@type string[]
    ---@diagnostic disable-next-line: assign-type-mismatch
    local handler_names = type(names) ~= "table" and { names } or names
    local removed_handlers = {}
    for _, name in ipairs(handler_names) do
        for i, handler in ipairs(handlers) do
            if handler.spec_field == name then
                table.remove(handlers, i)
                table.insert(removed_handlers, handler)
                break
            end
        end
    end
    return removed_handlers
end

-- It turns out that its faster when you copy paste.
-- Would be nice to just define it once, but then you lose 10ms
---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_enabled(spec)
    local disabled = spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
    return not disabled
end

---Register new handlers.
---Will refuse duplicates, and return a list of added handler spec_fields
---@param handler_list lze.Handler[]|lze.Handler|lze.HandlerSpec[]|lze.HandlerSpec
---@return string[]
function M.register_handlers(handler_list)
    assert(type(handler_list) == "table", "invalid argument to lze.register_handlers")
    if handler_list.spec_field or handler_list.handler then
        handler_list = { handler_list }
    end

    local existing_handler_fields = {}
    for _, hndl in ipairs(handlers) do
        existing_handler_fields[hndl.spec_field] = true
    end
    local added_names = {}
    for _, spec in ipairs(handler_list) do
        local handler = spec.spec_field and spec
            ---@cast spec lze.HandlerSpec
            or spec.handler and is_enabled(spec) and spec.handler
        local spec_field = handler and handler.spec_field or nil
        if spec_field and not existing_handler_fields[spec_field] then
            existing_handler_fields[spec_field] = true
            table.insert(added_names, spec_field)
            table.insert(handlers, handler)
        end
    end
    return added_names
end

---gets value for plugin.lazy by checking handler field useage
---@param spec lze.PluginSpec
---@return boolean
function M.is_lazy(spec)
    for _, hndl in ipairs(handlers) do
        if hndl.set_lazy ~= false and spec[hndl.spec_field] ~= nil then
            return true
        end
    end
    return false
end

---modify is called if the handler has a modify hook
---and then spec_field for that handler on the plugin
---is not nil
---@param plugin lze.Plugin
---@return lze.Plugin
function M.run_modify(plugin)
    ---@diagnostic disable-next-line: undefined-field
    local res = plugin
    local if_has_run = function(hndl, p)
        if not hndl.modify then
            return p
        end
        if p[hndl.spec_field] == nil then
            return p
        end
        return hndl.modify(p)
    end
    for _, hndl in ipairs(handlers) do
        res = if_has_run(hndl, res)
    end
    return res
end

---handlers can set up any of their own triggers for themselves here
---such as things like the event handler's DeferredUIEnter event
function M.run_post_def()
    for _, handler in ipairs(handlers) do
        if handler.post_def then
            handler.post_def()
        end
    end
end

---called after the plugin's load hook
---but before its after hook
---@param name string
function M.run_after(name)
    for _, handler in ipairs(handlers) do
        if handler.after then
            handler.after(name)
        end
    end
end

---called before the plugin's load hook
---but after its before hook
---@param name string
function M.run_before(name)
    for _, handler in ipairs(handlers) do
        if handler.before then
            handler.before(name)
        end
    end
end

---@param plugin lze.Plugin
local function enable(plugin)
    for _, handler in ipairs(handlers) do
        if handler.add then
            handler.add(vim.deepcopy(plugin))
        end
    end
end

-- calls add for all the handlers, each handler gets a copy, so that they
-- cannot change the plugin object recieved by the other handlers
-- outside of the modify step
---@param plugins lze.Plugin[]
function M.init(plugins)
    for _, plugin in ipairs(plugins) do
        enable(plugin)
    end
end

return M
