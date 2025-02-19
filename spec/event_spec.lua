---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.event", function()
    it("can parse from string", function()
        local f = function(inspec, evstr)
            local res = lze.h.event.parse(evstr)
            assert.Same(inspec.event, res.event)
            assert.Same(inspec.pattern, res.pattern)
            assert.Same(inspec.id, res.id)
        end
        f({
            event = "VimEnter",
            id = "VimEnter",
        }, "VimEnter")
    end)
    it("can parse from table", function()
        local f = function(inspec)
            local res = lze.h.event.parse({
                event = inspec.event,
                pattern = inspec.pattern,
            })
            assert.Same(inspec.event, res.event)
            assert.Same(inspec.pattern, res.pattern)
            assert.Same(inspec.id, res.id)
        end
        f({
            event = "VimEnter",
            id = "VimEnter",
        })
        f({
            event = { "VimEnter", "BufEnter" },
            id = "VimEnter|BufEnter",
        })
        f({
            event = "BufEnter",
            id = "BufEnter *.lua",
            pattern = "*.lua",
        })
    end)
    it("Event only loads plugin once", function()
        ---@type lze.Plugin
        local plugin = {
            name = "foo",
            event = { lze.h.event.parse("BufEnter") },
        }
        local spy_load = spy.on(loader, "load")
        lze.load(plugin)
        vim.api.nvim_exec_autocmds("BufEnter", {})
        vim.api.nvim_exec_autocmds("BufEnter", {})
        assert.spy(spy_load).called(1)
        assert.False(lze.state(plugin.name))
    end)
    it("Multiple events only load plugin once", function()
        ---@type table<string, number>
        local called_number = {}
        ---@param events lze.Event[]
        local function itt(events, name)
            ---@type lze.Plugin
            local plugin = {
                name = name,
                event = events,
                after = function(plugin)
                    called_number[plugin.name] = (called_number[plugin.name] or 0) + 1
                end,
            }
            local spy_load = spy.on(loader, "load")
            lze.load(plugin)
            vim.api.nvim_exec_autocmds(events[1].event, {
                pattern = ".lua",
            })
            vim.api.nvim_exec_autocmds(events[2].event, {
                pattern = ".lua",
            })
            assert.spy(spy_load).called_with({ plugin.name })
            assert.Equal(1, called_number[plugin.name])
            assert.False(lze.state(plugin.name))
        end
        itt({ lze.h.event.parse("BufEnter"), lze.h.event.parse("WinEnter") }, "foo2")
        itt({ lze.h.event.parse("WinEnter"), lze.h.event.parse("BufEnter") }, "foo3")
    end)
    it("Plugins' event handlers are triggered", function()
        local triggered = false
        ---@type lze.Plugin
        local plugin = {
            name = "foo6",
            event = { lze.h.event.parse("BufEnter") },
            after = function()
                triggered = true
            end,
        }
        ---@diagnostic disable-next-line: duplicate-set-field
        lze.load(plugin)
        vim.api.nvim_exec_autocmds("BufEnter", {})
        assert.True(triggered)
        assert.False(lze.state(plugin.name))
    end)
    it("DeferredUIEnter", function()
        ---@type lze.Plugin
        local plugin = {
            name = "bla",
            event = { lze.h.event.parse("DeferredUIEnter") },
        }
        local spy_load = spy.on(loader, "load")
        lze.load(plugin)
        vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
        assert.spy(spy_load).called(1)
        assert.False(lze.state(plugin.name))
    end)
end)
