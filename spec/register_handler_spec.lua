local lze = require("lze")
local test = require("gambiarra")

---@class state_entry
---@field load_called boolean
---@field after_load_called_after? boolean

---@type table<string, state_entry>
local plugin_state = {}

---@class TestHandler: lze.Handler
---@type TestHandler
local hndl = {
    spec_field = "testfield",
    add = function(_) end,
    before = function(_) end,
    after = function(name)
        if plugin_state[name] and plugin_state[name].load_called then
            plugin_state[name] = vim.tbl_extend("error", plugin_state[name], { after_load_called_after = true })
            return
        end
        plugin_state[name] = vim.tbl_extend("error", plugin_state[name] or {}, { after_load_called_after = false })
    end,
}

---@class TestHandler: lze.Handler
---@type TestHandler
local hndl2 = {
    spec_field = "testfield2",
    set_lazy = false,
}

local test_plugin = {
    "testplugin",
    testfield = { "a", "b" },
    load = function(plugin)
        plugin_state[plugin] = {
            load_called = true,
        }
    end,
}
local test_plugin_loaded = vim.tbl_extend("error", test_plugin, { lazy = true })
test_plugin_loaded.name = test_plugin_loaded[1]
test_plugin_loaded[1] = nil

local test_plugin2 = {
    "test_plugin2-not-lazy",
    testfield2 = { "a", "b" },
    load = function() end,
}

local test_plugin3 = {
    "testplugin3-is-lazy",
    testfield = { "a", "b" },
    testfield2 = { "a", "b" },
    load = function() end,
}
local test_plugin3_loaded = vim.tbl_extend("error", test_plugin3, { lazy = true })
test_plugin3_loaded.name = test_plugin3_loaded[1]
test_plugin3_loaded[1] = nil

test("register_handler tests", function()
    local addspy = spy.on(hndl, "add")
    local delspy = spy.on(hndl, "before")
    local afterspy = spy.on(hndl, "after")

    ok(eq({}, lze.register_handlers(require("lze.h.ft"))), "Duplicate handlers fail to register")
    ok(eq({ hndl.spec_field }, lze.register_handlers(hndl)), "It can register a handler")
    ok(eq({ hndl2.spec_field }, lze.register_handlers(hndl2)), "It can register another handler")

    lze.load(test_plugin)
    ok(addspy.called_with(test_plugin_loaded), "can add plugins to the handler")
    lze.trigger_load("testplugin")
    ok(delspy.called_with("testplugin"), "loading a plugin calls before")

    ok(afterspy.called_with("testplugin"), "called with the correct plugin name")
    ok(true == plugin_state["testplugin"].load_called, "load hook was called for the plugin")
    ok(true == plugin_state["testplugin"].after_load_called_after, "handler after was called after load")

    lze.load({ test_plugin2, test_plugin3 })
    ok(false == lze.state(test_plugin2.name), "handler can choose if it affects lazy setting (no effect)")
    ok(
        eq(lze.state[test_plugin3.name], test_plugin3_loaded),
        "handler can choose if it affects lazy setting (yes effect)"
    )
end)
