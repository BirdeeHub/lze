---@diagnostic disable: invisible
vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lze = require("lze")
local loader = require("lze.c.loader")
local test = require("gambiarra")

test("handlers.keys parses ids correctly", function()
    local tests = {
        { "<C-/>", "<c-/>", true },
        { "<C-h>", "<c-H>", true },
        { "<C-h>k", "<c-H>K", false },
    }
    for _, t in ipairs(tests) do
        if t[3] then
            ok(eq(lze.h.keys.parse(t[1])[1].id, lze.h.keys.parse(t[2])[1].id), "ids match")
        else
            ok(not eq(lze.h.keys.parse(t[1])[1].id, lze.h.keys.parse(t[2])[1].id), "ids differ")
        end
    end
end)

test("handlers.keys Key only loads plugin once", function()
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
    ok(eq(1, #spy_load.called), "load called once")
    ok(eq(false, lze.state(plugin.name)), "plugin not loaded")
    spy_load.off()
end)

test("handlers.keys Multiple keys only load plugin once", function()
    ---@param lzkeys string[]|lze.KeysSpec[]
    local function itt(lzkeys, name)
        local timesloaded = 0
        local parsed_keys = {}
        for _, key in ipairs(lzkeys) do
            table.insert(parsed_keys, lze.h.keys.parse(key)[1])
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
        ok(eq(1, timesloaded), "loaded once")
        ok(eq(false, lze.state(plugin.name)), "plugin not loaded")
    end
    itt({ "<leader>tt", "<leader>ff" }, "foody1")
    itt({ "<leader>ff", "<leader>tt" }, "foody2")
end)

test("handlers.keys Plugins' keymaps are triggered", function()
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
    ok(eq(true, triggered), "triggered is true")
    ok(eq(false, lze.state(plugin.name)), "plugin not loaded")
end)
