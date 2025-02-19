local M = {}

---@type lze.Handler[]
local handlers = vim.tbl_get(vim.g, "lze", "without_default_handlers") and {} or require("lze.h")
for _, handler in ipairs(handlers) do
    if handler.init then
        handler.init()
    end
end

local lib_meta = {
    __index = function(t, k)
        local h_lib
        for _, handler in ipairs(handlers) do
            if handler.spec_field == k then
                h_lib = handler.lib
                break
            end
        end
        if type(h_lib) ~= "table" then
            vim.schedule(function()
                vim.notify(
                    "handler '" .. k .. "' does not export any lib functions or is not registered",
                    vim.log.levels.ERROR,
                    { title = "lze" }
                )
            end)
            return nil
        end
        rawset(t, k, h_lib)
        return h_lib
    end,
    __newindex = function(t, k, v)
        rawset(t, k, v)
    end,
}

M.libs = setmetatable({}, lib_meta)

---Removes and returns all handlers
---@return lze.Handler[]
function M.clear_handlers()
    if vim.tbl_get(vim.g, "lze", "verbose") ~= false and #require("lze.c.loader").state ~= 0 then
        vim.schedule(function()
            vim.notify(
                "removing handlers while there are pending plugin specs may produce unpredictable behavior\n"
                    .. "If you know what you are doing, set vim.g.lze.verbose = false",
                vim.log.levels.ERROR,
                { title = "lze" }
            )
        end)
    end
    for _, handler in ipairs(handlers) do
        if handler.cleanup then
            handler.cleanup()
        end
    end
    local old_handlers = handlers
    handlers = {}
    M.libs = setmetatable({}, lib_meta)
    return old_handlers
end

---Removes and returns the named handlers (named by spec_field)
---@param names string|string[]
---@return lze.Handler[]
function M.remove_handlers(names)
    if vim.tbl_get(vim.g, "lze", "verbose") ~= false and #require("lze.c.loader").state ~= 0 then
        vim.schedule(function()
            vim.notify(
                "removing handlers while there are pending plugin specs may produce unpredictable behavior\n"
                    .. "If you know what you are doing, set vim.g.lze.verbose = false",
                vim.log.levels.ERROR,
                { title = "lze" }
            )
        end)
    end
    ---@type string[]
    ---@diagnostic disable-next-line: assign-type-mismatch
    local handler_names = type(names) ~= "table" and { names } or names
    local removed_handlers = {}
    for _, name in ipairs(handler_names) do
        for i, handler in ipairs(handlers) do
            if handler.spec_field == name then
                if handler.cleanup then
                    handler.cleanup()
                end
                table.remove(handlers, i)
                M.libs[name] = nil
                table.insert(removed_handlers, handler)
                break
            end
        end
    end
    return removed_handlers
end

---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_disabled(spec)
    return spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
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
            or spec.handler and not is_disabled(spec) and spec.handler
        local spec_field = handler and handler.spec_field or nil
        if spec_field and not existing_handler_fields[spec_field] then
            existing_handler_fields[spec_field] = true
            table.insert(added_names, spec_field)
            table.insert(handlers, handler)
            if handler.init then
                handler.init()
            end
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
    local if_has_run = function(hndl, p)
        if not hndl.modify then
            return p
        end
        if p[hndl.spec_field] == nil then
            return p
        end
        if is_disabled(p) then
            return p
        end
        return hndl.modify(p)
    end
    local res = plugin
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
