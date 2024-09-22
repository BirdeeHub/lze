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
    -- if single, make it a list anyway
    if handler_list.spec_field or handler_list.handler then
        handler_list = { handler_list }
    end
    local new_handlers = vim
        .iter(handler_list)
        -- normalize to handlerSpecs
        :map(function(spec)
            if spec.spec_field ~= nil then
                return { handler = spec }
            else
                return spec
            end
        end)
        -- filter our active, valid handlerSpecs
        :filter(function(spec)
            return spec.handler ~= nil and is_enabled(spec)
        end)
        -- normalize active handlers
        :map(function(spec)
            return spec.handler
        end)
        -- remove handlers already registered from list to add
        :filter(function(hndl)
            return vim.iter(handlers):all(function(hndlOG)
                return hndlOG.spec_field ~= hndl.spec_field
            end)
        end)
        :totable()

    -- remove internal duplicates
    local seen = {}
    local filtered_handlers = {}
    for _, item in ipairs(new_handlers) do
        if not seen[item] then
            seen[item] = true
            table.insert(filtered_handlers, item)
        end
    end

    vim.list_extend(handlers, filtered_handlers)
    return vim.iter(filtered_handlers)
        :map(function(hndl)
            return hndl.spec_field
        end)
        :totable()
end

---@param spec lze.PluginSpec
---@return boolean
function M.is_lazy(spec)
    ---@diagnostic disable-next-line: undefined-field
    return spec.lazy or vim.iter(handlers):any(function(hndl)
        return spec[hndl.spec_field] ~= nil
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
