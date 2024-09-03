-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local loader = require("lze.c.loader")

---@class lze.KeysHandler: lze.Handler

---@param value lze.KeysSpec
---@param mode? string
---@return lze.Keys
local function parse(value, mode)
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

---@type lze.KeysHandler
local M = {
    pending = {},
    spec_field = "keys",
    ---@param value string|lze.KeysSpec
    ---@return lze.Keys[]
    parse = function(value)
        value = type(value) == "string" and { value } or value --[[@as lze.KeysSpec]]
        local modes = type(value.mode) == "string" and { value.mode } or value.mode --[[ @as string[] | nil ]]
        if not modes then
            return { parse(value) }
        end
        return vim.iter(modes)
            :map(function(mode)
                return parse(value, mode)
            end)
            :totable()
    end,
}

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

-- Delete a mapping and create the real global
-- mapping when needed
---@param keys lze.Keys
local function del(keys)
    pcall(vim.keymap.del, keys.mode, keys.lhs, {
        -- NOTE: for buffer-local mappings, we only delete the mapping for the current buffer
        -- So the mapping could still exist in other buffers
        buffer = keys.ft and true or nil,
    })
    -- make sure to create global mappings when needed
    -- buffer-local mappings are managed by lze
    if not keys.ft then
        set(keys)
    end
end

---@param keys lze.Keys
local function add_keys(keys)
    local lhs = keys.lhs
    local opts = get_opts(keys)

    ---@param buf? number
    local function add(buf)
        vim.keymap.set(keys.mode, lhs, function()
            local plugins = M.pending[keys.id]
            -- always delete the mapping immediately to prevent recursive mappings
            del(keys)
            M.pending[keys.id] = nil
            if plugins then
                loader.load(vim.tbl_values(plugins))
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
            pattern = keys.ft,
            nested = true,
            callback = function(event)
                if M.pending[keys.id] then
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
end

---@param plugin lze.Plugin
function M.add(plugin)
    local keys_spec = plugin.keys
    if not keys_spec then
        return
    end
    local keys_def = {}
    if type(keys_spec) == "string" then
        local keys = M.parse(keys_spec)
        vim.list_extend(keys_def, keys)
    elseif type(keys_spec) == "table" then
        ---@param keys_spec_ string | lze.KeysSpec
        vim.iter(keys_spec):each(function(keys_spec_)
            local keys = M.parse(keys_spec_)
            vim.list_extend(keys_def, keys)
        end)
    end
    ---@param key lze.Keys
    vim.iter(keys_def or {}):each(function(key)
        M.pending[key.id] = M.pending[key.id] or {}
        M.pending[key.id][plugin.name] = plugin.name
        add_keys(key)
    end)
end

---@param name string
function M.before(name)
    vim.iter(M.pending):each(function(_, plugins)
        plugins[name] = nil
    end)
end

return M
