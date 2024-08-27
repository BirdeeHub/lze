---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local event = require("lze.h.event")
local state = require("lze.c.state")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.event", function()
    it("can parse from string", function()
        assert.same({
            event = "VimEnter",
            id = "VimEnter",
        }, event.parse("VimEnter"))
    end)
    it("can parse from table", function()
        assert.same(
            {
                event = "VimEnter",
                id = "VimEnter",
            },
            event.parse({
                event = "VimEnter",
            })
        )
        assert.same(
            {
                event = { "VimEnter", "BufEnter" },
                id = "VimEnter|BufEnter",
            },
            event.parse({
                event = { "VimEnter", "BufEnter" },
            })
        )
        assert.same(
            {
                event = "BufEnter",
                id = "BufEnter *.lua",
                pattern = "*.lua",
            },
            event.parse({
                event = "BufEnter",
                pattern = "*.lua",
            })
        )
    end)
    it("Event only loads plugin once", function()
        ---@type lze.Plugin
        local plugin = {
            name = "foo",
            event = { event.parse("BufEnter") },
        }
        local spy_load = spy.on(loader, "_load")
        state.plugins[plugin.name] = plugin
        event.add(plugin)
        vim.api.nvim_exec_autocmds("BufEnter", {})
        vim.api.nvim_exec_autocmds("BufEnter", {})
        assert.spy(spy_load).called(1)
        assert.True(state.loaded[plugin.name])
        state.loaded[plugin.name] = false
    end)
    it("Multiple events only load plugin once", function()
        ---@param events lze.Event[]
        local function itt(events)
            ---@type lze.Plugin
            local plugin = {
                name = "foo",
                event = events,
            }
            local spy_load = spy.on(loader, "_load")
            state.plugins[plugin.name] = plugin
            event.add(plugin)
            vim.api.nvim_exec_autocmds(events[1].event, {
                pattern = ".lua",
            })
            vim.api.nvim_exec_autocmds(events[2].event, {
                pattern = ".lua",
            })
            assert.spy(spy_load).called(1)
            assert.True(state.loaded[plugin.name])
            state.loaded[plugin.name] = false
        end
        itt({ event.parse("BufEnter"), event.parse("WinEnter") })
        itt({ event.parse("WinEnter"), event.parse("BufEnter") })
    end)
    it("Plugins' event handlers are triggered", function()
        ---@type lze.Plugin
        local plugin = {
            name = "foo",
            event = { event.parse("BufEnter") },
        }
        local triggered = false
        local orig_load = loader._load
        ---@diagnostic disable-next-line: duplicate-set-field
        loader._load = function(...)
            orig_load(...)
            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                    triggered = true
                end,
                group = vim.api.nvim_create_augroup("foo", {}),
            })
        end
        state.plugins[plugin.name] = plugin
        event.add(plugin)
        vim.api.nvim_exec_autocmds("BufEnter", {})
        assert.True(triggered)
        loader._load = orig_load
        assert.True(state.loaded[plugin.name])
        state.loaded[plugin.name] = false
    end)
    it("DeferredUIEnter", function()
        ---@type lze.Plugin
        local plugin = {
            name = "bla",
            event = { event.parse("DeferredUIEnter") },
        }
        local spy_load = spy.on(loader, "_load")
        state.plugins[plugin.name] = plugin
        event.add(plugin)
        vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
        assert.spy(spy_load).called(1)
        assert.True(state.loaded[plugin.name])
        state.loaded[plugin.name] = false
    end)
end)
