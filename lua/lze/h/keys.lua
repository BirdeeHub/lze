-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local loader = require("lze.c.loader")

local augroup = nil

---@param value lze.KeysSpec
---@param mode? string
---@return lze.Keys
local function _parse(value, mode)
    local ret = vim.deepcopy(value) --[[@as lze.Keys]]
    ret.lhs = ret[1] or ""
    ret.rhs = ret[2]
    ret[1] = nil
    ret[2] = nil
    ret.mode = mode or "n"
    ret.id = vim.api.nvim_replace_termcodes(ret.lhs, true, true, true)
    if ret.ft then
        local ft = type(ret.ft) == "string" and { ret.ft } or ret.ft --[[@as string[] ]]
        ret.id = ret.id .. " (" .. table.concat(ft, ", ") .. ")"
    end
    if ret.mode ~= "n" then
        ret.id = ret.id .. " (" .. ret.mode .. ")"
    end
    return ret
end

---@param value string|lze.KeysSpec
---@return lze.Keys[]
local function parse(value)
    value = type(value) == "string" and { value } or value --[[@as lze.KeysSpec]]
    local modes = type(value.mode) == "string" and { value.mode } or value.mode --[[ @as string[] | nil ]]
    if not modes then
        return { _parse(value) }
    end
    return vim.iter(modes)
        :map(function(mode)
            return _parse(value, mode)
        end)
        :totable()
end

---@param keys lze.Keys
local function is_nop(keys)
    return type(keys.rhs) == "string" and (keys.rhs == "" or keys.rhs:lower() == "<nop>")
end

local states = {}

---@type lze.Handler
local M = {
    spec_field = "keys",
    lib = {
        parse = parse,
    },
}

function M.init()
    augroup = vim.api.nvim_create_augroup("lze_handler_keys_ft", { clear = true })
end

local skip = { mode = true, id = true, ft = true, rhs = true, lhs = true }

---@param keys lze.Keys
---@return lze.KeysBase
local function get_opts(keys)
    ---@type lze.KeysBase
    return vim.iter(keys):fold({}, function(acc, k, v)
        if type(k) ~= "number" and not skip[k] then
            acc[k] = v
        end
        return acc
    end)
end

-- Create a mapping if it is managed by lze
---@param keys lze.Keys
---@param buf integer?
local function set(keys, buf)
    if keys.rhs then
        local opts = get_opts(keys)
        ---@diagnostic disable-next-line: inject-field
        opts.buffer = buf
        vim.keymap.set(keys.mode, keys.lhs, keys.rhs, opts)
    end
end

---@param keys lze.Keys
local function add_keys(keys)
    local del = function()
        pcall(vim.keymap.del, keys.mode, keys.lhs, {
            -- NOTE: for buffer-local mappings, we only delete the mapping for the current buffer
            -- So the mapping could still exist in other buffers
            buffer = keys.ft and true or nil,
        })
    end
    local lhs = keys.lhs
    local opts = get_opts(keys)

    ---@param buf? number
    local function add(buf)
        if is_nop(keys) then
            return set(keys, buf)
        end
        vim.keymap.set(keys.mode, lhs, function()
            local plugins = states[keys.id]
            -- always delete the mapping immediately to prevent recursive mappings
            del()
            -- make sure to create global mappings when needed
            -- buffer-local mappings are managed by lze
            if not keys.ft then
                set(keys)
            end
            states[keys.id] = nil
            if plugins then
                loader.load(vim.tbl_keys(plugins))
            end
            -- Create the real buffer-local mapping
            if keys.ft then
                set(keys, buf)
            end
            if keys.mode:sub(-1) == "a" then
                lhs = lhs .. "<C-]>"
            end
            local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
            -- insert instead of append the lhs
            vim.api.nvim_feedkeys(feed, "i", false)
        end, {
            desc = opts.desc,
            nowait = opts.nowait,
            -- we do not return anything, but this is still needed to make operator pending mappings work
            expr = true,
            buffer = buf,
        })
    end
    -- buffer-local mappings
    if keys.ft then
        vim.api.nvim_create_autocmd("FileType", {
            group = augroup,
            pattern = keys.ft,
            nested = true,
            callback = function(event)
                if states[keys.id] then
                    add(event.buf)
                else
                    -- Only create the mapping if its managed by lze
                    -- otherwise the plugin is supposed to manage it
                    set(keys, event.buf)
                end
            end,
        })
    else
        add()
    end
    return del
end

---@param plugin lze.Plugin
function M.add(plugin)
    local keys_spec = plugin.keys
    if not keys_spec then
        return
    end
    local keys_def = {}
    if type(keys_spec) == "string" then
        local keys = parse(keys_spec)
        vim.list_extend(keys_def, keys)
    elseif type(keys_spec) == "table" then
        ---@param keys_spec_ string | lze.KeysSpec
        vim.iter(keys_spec):each(function(keys_spec_)
            local keys = parse(keys_spec_)
            vim.list_extend(keys_def, keys)
        end)
    end
    ---@param key lze.Keys
    vim.iter(keys_def or {}):each(function(key)
        states[key.id] = states[key.id] or {}
        states[key.id][plugin.name] = add_keys(key)
    end)
end

---@param name string
function M.before(name)
    vim.iter(states):each(function(_, plugins)
        plugins[name] = nil
    end)
end

function M.cleanup()
    if augroup then
        vim.api.nvim_del_augroup_by_id(augroup)
    end
    vim.iter(states):each(function(_, plugins)
        for _, del in pairs(plugins) do
            del()
        end
    end)
    states = {}
end

return M
