local lze = require("lze")
local spy = require("luassert.spy")

describe("handlers.custom", function()
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

    local addspy = spy.on(hndl, "add")
    local delspy = spy.on(hndl, "before")
    local afterspy = spy.on(hndl, "after")

    it("Duplicate handlers fail to register", function()
        assert.same({}, lze.register_handlers(require("lze.h.ft")))
    end)
    it("can add plugins to the handler", function()
        assert.same({ hndl.spec_field }, lze.register_handlers(hndl))
        assert.same({ hndl2.spec_field }, lze.register_handlers(hndl2))
        lze.load(test_plugin)
        assert.spy(addspy).called_with(test_plugin_loaded)
    end)
    it("loading a plugin calls before", function()
        lze.trigger_load("testplugin")
        assert.spy(delspy).called_with("testplugin")
    end)
    it("handler after is called after load", function()
        assert.spy(afterspy).called_with("testplugin")
        assert.True(plugin_state["testplugin"].load_called)
        assert.True(plugin_state["testplugin"].after_load_called_after)
    end)
    it("can choose if it affects lazy setting", function()
        lze.load({ test_plugin2, test_plugin3 })
        assert.False(lze.state(test_plugin2.name))
        assert.same(lze.state[test_plugin3.name], test_plugin3_loaded)
    end)
end)
