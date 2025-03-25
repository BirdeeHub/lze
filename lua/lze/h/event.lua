-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local loader = require("lze.c.loader")

---@class lze.EventOpts
---@field event string
---@field group? string
---@field exclude? string[] augroups to exclude
---@field data? unknown
---@field buffer? number

local alias_events = {
    DeferredUIEnter = { id = "User DeferredUIEnter", event = "User", pattern = "DeferredUIEnter" },
}

local pending = {}
---@type integer
local augroup = nil
local deferred_enter_event_id = nil

---@type fun(spec: lze.EventSpec): lze.Event
local parse = function(spec)
    local ret = alias_events[spec]
    if ret then
        ret.augroup = ret.augroup or augroup
        return ret
    end
    if type(spec) == "string" then
        local event, pattern = spec:match("^(%w+)%s+(.*)$")
        event = event or spec
        return { id = spec, event = event, pattern = pattern, augroup = augroup }
    elseif vim.islist(spec) then
        ret = { id = table.concat(spec, "|"), event = spec, augroup = augroup }
    else
        ret = spec --[[@as lze.Event]]
        if not ret.id then
            ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
            ret.id = type(ret.event) == "string" and ret.event
                or ret.event == nil and "*"
                ---@diagnostic disable-next-line: param-type-mismatch
                or table.concat(ret.event, "|")
            if ret.pattern then
                ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
                ret.id = ret.id
                    .. " "
                    .. (
                        type(ret.pattern) == "string" and ret.pattern
                        or table.concat(ret.pattern --[[@as table]], ", ")
                    )
            end
        end
        ret.augroup = ret.augroup or augroup
    end
    return ret
end

---@type lze.Handler
local M = {
    spec_field = "event",
    lib = {
        parse = parse,
        ---@param name string
        ---@param spec lze.EventSpec
        set_event_alias = function(name, spec)
            alias_events[name] = spec and parse(spec) or nil
        end,
    },
}

local deferred_ui_enter = vim.schedule_wrap(function()
    if vim.v.exiting ~= vim.NIL then
        return
    end
    vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
end)

function M.init()
    augroup = vim.api.nvim_create_augroup("lze_handler_event", { clear = true })
    deferred_enter_event_id = vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        nested = true,
        callback = deferred_ui_enter,
    })
end

function M.post_def()
    if vim.v.vim_did_enter == 1 then
        deferred_ui_enter()
    end
end

-- Get all augroups for an event
---@param event string
---@return string[]
local function get_augroups(event)
    local ret = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
        if autocmd.group_name ~= nil then
            table.insert(ret, autocmd.group_name)
        end
    end
    return ret
end

-- Get the current state of the event and all the events that will be fired
---@param event string
---@param buf integer
---@param data unknown
---@return lze.EventOpts
local function get_state(event, buf, data)
    ---@type lze.EventOpts
    return {
        event = event,
        exclude = get_augroups(event),
        buffer = buf,
        data = data,
    }
end

-- Trigger an event
---@param opts lze.EventOpts
local function _trigger(opts)
    xpcall(
        function()
            vim.api.nvim_exec_autocmds(opts.event, {
                buffer = opts.buffer,
                group = opts.group,
                modeline = false,
                data = opts.data,
            })
        end,
        vim.schedule_wrap(function(err)
            vim.notify(err, vim.log.levels.ERROR)
        end)
    )
end

-- Trigger an event. When a group is given, only the events in that group will be triggered.
-- When exclude is set, the events in those groups will be skipped.
---@param opts lze.EventOpts
local function trigger(opts)
    if opts.group or opts.exclude == nil then
        return _trigger(opts)
    end
    ---@type table<string,true>
    local done = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = opts.event })) do
        local id = autocmd.event .. ":" .. (autocmd.group or "") ---@type string
        local skip = done[id] or (opts.exclude and vim.tbl_contains(opts.exclude, autocmd.group_name))
        done[id] = true
        if autocmd.group and not skip then
            ---@diagnostic disable-next-line: assign-type-mismatch
            opts.group = autocmd.group_name
            _trigger(opts)
        end
    end
end

---@param event lze.Event
local function add_event(event)
    local done = false
    vim.api.nvim_create_autocmd(event.event, {
        group = event.augroup,
        once = true,
        nested = true,
        pattern = event.pattern,
        callback = function(ev)
            if done or not pending[event.id] then
                return
            end
            -- HACK: work-around for https://github.com/neovim/neovim/issues/25526
            done = true
            local state = get_state(ev.event, ev.buf, ev.data)
            -- load the plugins
            loader.load(vim.tbl_keys(pending[event.id]))
            -- check if any plugin created an event handler for this event and fire the group
            trigger(state)
        end,
    })
end

---@param plugin lze.Plugin
function M.add(plugin)
    local event_spec = plugin.event
    if not event_spec then
        return
    end
    local event_def = {}
    if type(event_spec) == "string" then
        local event = parse(event_spec)
        table.insert(event_def, event)
    elseif type(event_spec) == "table" then
        ---@param ev lze.EventSpec[]
        for _, ev in ipairs(event_spec) do
            local event = parse(ev)
            table.insert(event_def, event)
        end
    end
    ---@param event lze.Event
    for _, event in ipairs(event_def or {}) do
        pending[event.id] = pending[event.id] or {}
        pending[event.id][plugin.name] = event.augroup
        add_event(event)
    end
end

---@param name string
function M.before(name)
    for _, plugins in pairs(pending) do
        plugins[name] = nil
    end
end

function M.cleanup()
    for _, plugins in pairs(pending) do
        for k, p in pairs(plugins) do
            if p == augroup then
                plugins[k] = nil
            end
        end
    end
    if augroup then
        vim.api.nvim_del_augroup_by_id(augroup)
    end
    if deferred_enter_event_id then
        vim.api.nvim_del_autocmd(deferred_enter_event_id)
    end
end

return M
