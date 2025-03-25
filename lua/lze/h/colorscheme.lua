-- NOTE: internal handlers must use internal trigger_load
-- because require('lze') requires this module.
local loader = require("lze.c.loader")

local states = {}
local augroup = nil

---@type lze.Handler
local M = {
    spec_field = "colorscheme",
}

---@param name string
function M.before(name)
    for _, plugins in pairs(states) do
        plugins[name] = nil
    end
end

---@param name string
local function on_colorscheme(name)
    local pending = states[name] or {}
    if vim.tbl_isempty(pending) then
        -- already loaded
        return
    end
    loader.load(vim.tbl_values(pending))
end

function M.init()
    augroup = vim.api.nvim_create_augroup("lze_handler_colorscheme", { clear = true })
    vim.api.nvim_create_autocmd("ColorSchemePre", {
        callback = function(event)
            on_colorscheme(event.match)
        end,
        nested = true,
        group = augroup,
    })
end

---@param plugin lze.Plugin
function M.add(plugin)
    local colorscheme_spec = plugin.colorscheme
    if not colorscheme_spec then
        return
    end
    local colorscheme_def = {}
    if type(colorscheme_spec) == "string" then
        table.insert(colorscheme_def, colorscheme_spec)
    elseif type(colorscheme_spec) == "table" then
        ---@param colorscheme_spec_ string
        for _, colorscheme_spec_ in ipairs(colorscheme_spec) do
            table.insert(colorscheme_def, colorscheme_spec_)
        end
    end
    ---@param colorscheme string
    for _, colorscheme in ipairs(colorscheme_def) do
        states[colorscheme] = states[colorscheme] or {}
        states[colorscheme][plugin.name] = plugin.name
    end
end

function M.cleanup()
    if augroup then
        vim.api.nvim_del_augroup_by_id(augroup)
    end
    states = {}
end

return M
