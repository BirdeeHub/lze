---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local keys = require("lze.h.keys")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.keys", function()
    it("parses ids correctly", function()
        local tests = {
            { "<C-/>", "<c-/>", true },
            { "<C-h>", "<c-H>", true },
            { "<C-h>k", "<c-H>K", false },
        }
        for _, test in ipairs(tests) do
            if test[3] then
                assert.same(keys.parse(test[1])[1].id, keys.parse(test[2])[1].id)
            else
                assert.is_not.same(keys.parse(test[1])[1].id, keys.parse(test[2])[1].id)
            end
        end
    end)
    it("Key only loads plugin once", function()
        local lhs = "<leader>tt"
        ---@type lze.Plugin
        local plugin = {
            name = "food",
            keys = lhs,
        }
        local spy_load = spy.on(loader, "load")
        lze.load(plugin)
        local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
        vim.api.nvim_feedkeys(feed, "ix", false)
        vim.api.nvim_feedkeys(feed, "ix", false)
        assert.spy(spy_load).called(1)
        assert.False(lze.query_state(plugin.name))
    end)
    it("Multiple keys only load plugin once", function()
        ---@param lzkeys string[]|lze.KeysSpec[]
        local function itt(lzkeys, name)
            local timesloaded = 0
            local parsed_keys = {}
            for _, key in ipairs(lzkeys) do
                table.insert(parsed_keys, keys.parse(key)[1])
            end
            ---@type lze.Plugin
            local plugin = {
                name = name,
                keys = lzkeys,
                load = function()
                    timesloaded = timesloaded + 1
                end,
            }
            lze.load(plugin)
            local feed1 = vim.api.nvim_replace_termcodes("<Ignore>" .. parsed_keys[1].lhs, true, true, true)
            vim.api.nvim_feedkeys(feed1, "ix", false)
            local feed2 = vim.api.nvim_replace_termcodes("<Ignore>" .. parsed_keys[2].lhs, true, true, true)
            vim.api.nvim_feedkeys(feed2, "ix", false)
            assert.Equal(1, timesloaded)
            assert.False(lze.query_state(plugin.name))
        end
        itt({ "<leader>tt", "<leader>ff" }, "foody1")
        itt({ "<leader>ff", "<leader>tt" }, "foody2")
    end)
    it("Plugins' keymaps are triggered", function()
        local lhs = "<leader>xy"
        local triggered = false
        ---@type lze.Plugin
        local plugin = {
            name = "bazzite",
            keys = lhs,
            after = function()
                vim.keymap.set("n", lhs, function()
                    triggered = true
                end)
            end,
        }
        lze.load(plugin)
        local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
        vim.api.nvim_feedkeys(feed, "ix", false)
        vim.api.nvim_feedkeys(feed, "x", false)
        assert.True(triggered)
        assert.False(lze.query_state(plugin.name))
    end)
end)
