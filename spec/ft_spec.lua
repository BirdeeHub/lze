---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.ft", function()
    it("can parse from string", function()
        local f = function(inspec, ft)
            local res = lze.h.ft.parse(ft)
            assert.Same(inspec.event, res.event)
            assert.Same(inspec.pattern, res.pattern)
            assert.Same(inspec.id, res.id)
        end
        f({
            event = "FileType",
            id = "rust",
            pattern = "rust",
        }, "rust")
    end)
    it("filetype event loads plugins", function()
        ---@type lze.Plugin
        local plugin = {
            name = "Foo",
            ft = { "rust" },
        }
        local spy_load = spy.on(loader, "load")
        lze.load(plugin)
        vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
        vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
        assert.spy(spy_load).called(1)
    end)
end)
