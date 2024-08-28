-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local loader = require("lze.c.loader")

---@class lze.EventOpts
---@field event string
---@field group? string
---@field exclude? string[] augroups to exclude
---@field data? unknown
---@field buffer? number

---@class lze.EventHandler: lze.Handler
---@field events table<string,true>
---@field group number
---@field parse fun(spec: lze.EventSpec): lze.Event

local lze_events = {
    DeferredUIEnter = { id = "DeferredUIEnter", event = "User", pattern = "DeferredUIEnter" },
}

lze_events["User DeferredUIEnter"] = lze_events.DeferredUIEnter

---@type lze.EventHandler
local M = {
    pending = {},
    events = {},
    group = vim.api.nvim_create_augroup("lze_handler_event", { clear = true }),
    spec_field = "event",
    ---@param spec lze.EventSpec
    parse = function(spec)
        local ret = lze_events[spec]
        if ret then
            return ret
        end
        if type(spec) == "string" then
            local event, pattern = spec:match("^(%w+)%s+(.*)$")
            event = event or spec
            return { id = spec, event = event, pattern = pattern }
        elseif vim.islist(spec) then
            ret = { id = table.concat(spec, "|"), event = spec }
        else
            ret = spec --[[@as lze.Event]]
            if not ret.id then
                ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
                ret.id = type(ret.event) == "string" and ret.event or table.concat(ret.event, "|")
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
        end
        return ret
    end,
}

local deferred_ui_enter = vim.schedule_wrap(function()
    if vim.v.exiting ~= vim.NIL then
        return
    end
    vim.g.lze_did_deferred_ui_enter = true
    vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
end)

function M.post_def()
    if vim.v.vim_did_enter == 1 then
        deferred_ui_enter()
    elseif not vim.g.lze_did_create_deferred_ui_enter_autocmd then
        vim.api.nvim_create_autocmd("UIEnter", {
            once = true,
            callback = deferred_ui_enter,
        })
        vim.g.lze_did_create_deferred_ui_enter_autocmd = true
    end
end

-- Get all augroups for an event
---@param event string
---@return string[]
local function get_augroups(event)
    return vim.iter(vim.api.nvim_get_autocmds({ event = event }))
        :filter(function(autocmd)
            return autocmd.group_name ~= nil
        end)
        :map(function(autocmd)
            return autocmd.group_name
        end)
        :totable()
end

local event_triggers = {
    FileType = "BufReadPost",
    BufReadPost = "BufReadPre",
}
-- Get the current state of the event and all the events that will be fired
---@param event string
---@param buf integer
---@param data unknown
---@return lze.EventOpts[]
local function get_state(event, buf, data)
    ---@type lze.EventOpts[]
    local state = {}
    while event do
        ---@type lze.EventOpts
        local event_opts = {
            event = event,
            exclude = event ~= "FileType" and get_augroups(event) or nil,
            buffer = buf,
            data = data,
        }
        table.insert(state, 1, event_opts)
        data = nil -- only pass the data to the first event
        event = event_triggers[event]
    end
    return state
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
    vim.iter(vim.api.nvim_get_autocmds({ event = opts.event })):each(function(autocmd)
        local id = autocmd.event .. ":" .. (autocmd.group or "") ---@type string
        local skip = done[id] or (opts.exclude and vim.tbl_contains(opts.exclude, autocmd.group_name))
        done[id] = true
        if autocmd.group and not skip then
            ---@diagnostic disable-next-line: assign-type-mismatch
            opts.group = autocmd.group_name
            _trigger(opts)
        end
    end)
end

---@param event lze.Event
local function add_event(event)
    local done = false
    vim.api.nvim_create_autocmd(event.event, {
        group = M.group,
        once = true,
        pattern = event.pattern,
        callback = function(ev)
            if done or not M.pending[event.id] then
                return
            end
            -- HACK: work-around for https://github.com/neovim/neovim/issues/25526
            done = true
            local state = get_state(ev.event, ev.buf, ev.data)
            -- load the plugins
            loader.load(vim.tbl_values(M.pending[event.id]))
            -- check if any plugin created an event handler for this event and fire the group
            ---@param s lze.EventOpts
            vim.iter(state):each(function(s)
                trigger(s)
            end)
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
        local event = M.parse(event_spec)
        table.insert(event_def, event)
    elseif type(event_spec) == "table" then
        ---@param ev lze.EventSpec[]
        vim.iter(event_spec):each(function(ev)
            local event = M.parse(ev)
            table.insert(event_def, event)
        end)
    end
    ---@param event lze.Event
    vim.iter(event_def or {}):each(function(event)
        M.pending[event.id] = M.pending[event.id] or {}
        M.pending[event.id][plugin.name] = plugin.name
        add_event(event)
    end)
end

---@param name string
function M.before(name)
    vim.iter(M.pending):each(function(_, plugins)
        plugins[name] = nil
    end)
end

return M
