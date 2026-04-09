---@diagnostic disable: invisible
vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lze = require("lze")
local loader = require("lze.c.loader")
local test = ...

test("Filetype handler parses filetype string correctly", function()
    local f = function(inspec, ft)
        local res = lze.h.ft.parse(ft)
        ok(eq(inspec.event, res.event), "parsed event matches expected event")
        ok(eq(inspec.pattern, res.pattern), "parsed pattern matches expected pattern")
        ok(eq(inspec.id, res.id), "parsed id matches expected id")
    end
    f({
        event = "FileType",
        id = "rust",
        pattern = "rust",
    }, "rust")
end)

test("Filetype event loads plugin when filetype is triggered", function()
    ---@type lze.Plugin
    local plugin = {
        name = "Foo",
        ft = { "rust" },
    }
    local spy_load = spy.on(loader, "load")
    lze.load(plugin)
    vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
    vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
    ok(1 == #spy_load.called, "plugin loaded exactly once when filetype triggers")
    spy_load.off()
end)
