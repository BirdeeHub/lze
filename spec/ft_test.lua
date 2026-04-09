---@diagnostic disable: invisible
vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lze = require("lze")
local loader = require("lze.c.loader")
local test = ...

test("handlers.ft can parse from string", function()
    local f = function(inspec, ft)
        local res = lze.h.ft.parse(ft)
        ok(eq(inspec.event, res.event), "event matches")
        ok(eq(inspec.pattern, res.pattern), "pattern matches")
        ok(eq(inspec.id, res.id), "id matches")
    end
    f({
        event = "FileType",
        id = "rust",
        pattern = "rust",
    }, "rust")
end)

test("handlers.ft filetype event loads plugins", function()
    ---@type lze.Plugin
    local plugin = {
        name = "Foo",
        ft = { "rust" },
    }
    local spy_load = spy.on(loader, "load")
    lze.load(plugin)
    vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
    vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
    ok(eq(1, #spy_load.called), "load called once")
    spy_load.off()
end)
