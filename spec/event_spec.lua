---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local loader = require("lze.c.loader")
local test = require("gambiarra")

test("can parse from string", function()
    local f = function(inspec, evstr)
        local res = lze.h.event.parse(evstr)
        ok(eq(res.event, inspec.event), "event")
        ok(eq(res.pattern, inspec.pattern), "pattern")
        ok(eq(res.id, inspec.id), "id")
    end
    f({
        event = "VimEnter",
        id = "VimEnter",
    }, "VimEnter")
end)
test("can parse from table", function()
    local f = function(inspec)
        local res = lze.h.event.parse({
            event = inspec.event,
            pattern = inspec.pattern,
        })
        ok(eq(res.event, inspec.event), "event")
        ok(eq(res.pattern, inspec.pattern), "pattern")
        ok(eq(res.id, inspec.id), "id")
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
test("Event only loads plugin once", function()
    ---@type lze.Plugin
    local plugin = {
        name = "foo",
        event = { lze.h.event.parse("BufEnter") },
    }
    local spy_load = spy.on(loader, "load")
    lze.load(plugin)
    vim.api.nvim_exec_autocmds("BufEnter", {})
    vim.api.nvim_exec_autocmds("BufEnter", {})
    ok(#spy_load.called == 1, "event only loaded once")
    ok(lze.state(plugin.name) == false, "plugin state is now false")
    spy_load.off()
end)
test("Multiple events only load plugin once", function()
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
        ok(spy_load.called_with({ plugin.name }), "load called with correct plugin name")
        ok(called_number[plugin.name] == 1, "called with this plugin once")
        ok(lze.state(plugin.name) == false, "plugin state is now false")
    end
    itt({ lze.h.event.parse("BufEnter"), lze.h.event.parse("WinEnter") }, "foo2")
    itt({ lze.h.event.parse("WinEnter"), lze.h.event.parse("BufEnter") }, "foo3")
end)
test("Plugins' event handlers are triggered", function()
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
    ok(triggered == true, "event handler triggered")
    ok(lze.state(plugin.name) == false, "plugin state is now false")
end)
test("DeferredUIEnter", function()
    ---@type lze.Plugin
    local plugin = {
        name = "bla",
        event = { lze.h.event.parse("DeferredUIEnter") },
    }
    local spy_load = spy.on(loader, "load")
    lze.load(plugin)
    vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter", modeline = false })
    ok(#spy_load.called == 1, "spec only loaded once")
    ok(lze.state(plugin.name) == false, "plugin state is now false")
end)
