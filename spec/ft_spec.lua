---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local ft = require("lze.h.ft")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.ft", function()
    it("can parse from string", function()
        assert.same({
            event = "FileType",
            id = "rust",
            pattern = "rust",
        }, ft.parse("rust"))
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
