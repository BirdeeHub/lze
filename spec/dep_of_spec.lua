local lze = require("lze")

describe("handlers.dep_of", function()
    ---@class state_entry_deps
    ---@field load_called? boolean
    ---@field after_called? boolean
    ---@field before_called? boolean
    ---@field loaded_after? string[]
    ---@field loaded_after_before? string[]
    ---@field loaded_after_after? string[]

    ---@type table<string, state_entry_deps>
    local plugin_state = {}

    local filter_states = function(plugin, filter)
        local result = {}
        for name, state in pairs(plugin_state) do
            if name ~= plugin.name and filter(name, state) then
                table.insert(result, name)
            end
        end
        return result
    end

    local test_load_fun = function(plugin)
        if plugin_state[plugin] == nil then
            plugin_state[plugin] = {}
        end
        plugin_state[plugin] = vim.tbl_extend("force", plugin_state[plugin], {
            load_called = true,
            loaded_after = filter_states(plugin, function(_, v)
                return v.load_called
            end),
            loaded_after_after = filter_states(plugin, function(_, v)
                return v.after_called
            end),
            loaded_after_before = filter_states(plugin, function(_, v)
                return v.before_called
            end),
        })
    end

    local test_before_fun = function(plugin)
        if plugin_state[plugin.name] == nil then
            plugin_state[plugin.name] = {}
        end
        plugin_state[plugin.name].before_called = true
    end
    local test_after_fun = function(plugin)
        if plugin_state[plugin.name] == nil then
            plugin_state[plugin.name] = {}
        end
        plugin_state[plugin.name].after_called = true
    end

    local tpl = {
        name = "test_plugin_3",
        lazy = true,
        load = test_load_fun,
        before = test_before_fun,
        after = test_after_fun,
    }
    local tpl_2 = {
        name = "test_plugin_4",
        dep_of = { "test_plugin_3" },
        load = test_load_fun,
        before = test_before_fun,
        after = test_after_fun,
    }

    it("dep_of loads after before and before load", function()
        lze.load(tpl_2)
        lze.load(tpl)
        lze.trigger_load(tpl.name)

        assert.same(true, plugin_state[tpl.name].load_called)
        assert.same(true, plugin_state[tpl.name].before_called)
        assert.same(true, plugin_state[tpl.name].after_called)
        assert.same({ "test_plugin_4" }, plugin_state[tpl.name].loaded_after)
        assert.same({ "test_plugin_4" }, plugin_state[tpl.name].loaded_after_after)
        assert.True(vim.tbl_contains(plugin_state[tpl.name].loaded_after_before, "test_plugin_3"))
        assert.True(vim.tbl_contains(plugin_state[tpl.name].loaded_after_before, "test_plugin_4"))

        assert.same(true, plugin_state[tpl_2.name].load_called)
        assert.same(true, plugin_state[tpl_2.name].before_called)
        assert.same(true, plugin_state[tpl_2.name].after_called)
        assert.same({}, plugin_state[tpl_2.name].loaded_after)
        assert.same({}, plugin_state[tpl_2.name].loaded_after_after)
        assert.True(vim.tbl_contains(plugin_state[tpl_2.name].loaded_after_before, "test_plugin_3"))
        assert.True(vim.tbl_contains(plugin_state[tpl_2.name].loaded_after_before, "test_plugin_4"))
    end)
end)
