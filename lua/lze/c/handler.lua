local M = {}

local handlers = require("lze.h")

---@return lze.Handler[]
function M.clear_handlers()
    local old_handlers = handlers
    handlers = {}
    return old_handlers
end

-- It turns out that its faster when you copy paste
-- Would be nice to just define it
-- once, but then you lose 10ms
---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_enabled(spec)
    local disabled = spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
    return not disabled
end

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
    local filtered_handlers = {}
    for _, spec in ipairs(handler_list) do
        if spec.spec_field and not existing_handler_fields[spec.spec_field] then
            existing_handler_fields[spec.spec_field] = true
            table.insert(added_names, spec.spec_field)
            table.insert(filtered_handlers, spec)
        elseif
            spec.handler
            and spec.handler.spec_field
            ---@cast spec lze.HandlerSpec
            and is_enabled(spec)
            and not existing_handler_fields[spec.handler.spec_field]
        then
            existing_handler_fields[spec.handler.spec_field] = true
            table.insert(added_names, spec.handler.spec_field)
            table.insert(filtered_handlers, spec.handler)
        end
    end

    vim.list_extend(handlers, filtered_handlers)
    return added_names
end

---@param spec lze.PluginSpec
---@return boolean
function M.is_lazy(spec)
    return vim.iter(handlers):any(function(hndl)
        return hndl.set_lazy ~= false and spec[hndl.spec_field]
    end)
end

---@param plugin lze.Plugin
---@return lze.Plugin
function M.run_modify(plugin)
    ---@diagnostic disable-next-line: undefined-field
    local res = plugin
    local if_has_run = function(hndl, p)
        if not hndl.modify then
            return p
        end
        if not p[hndl.spec_field] then
            return p
        end
        return hndl.modify(p)
    end
    for _, hndl in ipairs(handlers) do
        res = if_has_run(hndl, res)
    end
    return res
end

function M.run_post_def()
    for _, handler in ipairs(handlers) do
        ---@cast handler lze.Handler
        if handler.post_def then
            handler.post_def()
        end
    end
end

---@param name string
function M.run_after(name)
    for _, handler in ipairs(handlers) do
        ---@cast handler lze.Handler
        if handler.after then
            handler.after(name)
        end
    end
end

---@param name string
function M.run_before(name)
    for _, handler in ipairs(handlers) do
        ---@cast handler lze.Handler
        if handler.before then
            handler.before(name)
        end
    end
end

---@param plugin lze.Plugin
local function enable(plugin)
    for _, handler in ipairs(handlers) do
        if handler.add then
            ---@cast handler lze.Handler
            handler.add(vim.deepcopy(plugin))
        end
    end
end

---@param plugins lze.Plugin[]
function M.init(plugins)
    ---@param plugin lze.Plugin
    for _, plugin in ipairs(plugins) do
        enable(plugin)
    end
end

return M
