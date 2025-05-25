local lze = require("lze")
local spy = require("luassert.spy")
local dummy = function(name)
    return name
end
local reqspy = spy.new(dummy)
local loadspy = spy.new(dummy)
local function mktestplug(name, target)
    return {
        name = name,
        on_require = { name },
        load = function(n)
            loadspy(n)
            package.preload[n] = function()
                return reqspy(n)
            end
            if target then
                require(target)
            end
        end,
    }
end

describe("handlers.on_require", function()
    it("require loads plugins", function()
        local name = "lze_test_require_mod"
        ---@type lze.Plugin
        lze.load(mktestplug(name))
        require(name)
        assert.spy(loadspy).called_with(name)
        assert.spy(reqspy).called_with(name)
        package.preload[name] = nil
        package.loaded[name] = nil
    end)
    it("handles nested plugins", function()
        local name = "lze_test_require_mod_1"
        local name2 = "lze_test_require_mod_2"
        local name3 = "lze_test_require_mod_3"
        ---@type lze.Plugin
        lze.load({
            mktestplug(name),
            mktestplug(name2, name),
            mktestplug(name3, name2),
        })
        assert.equal(name3, require(name3))
        for _, n in ipairs({ name, name2, name3 }) do
            assert.spy(loadspy).called_with(n)
            assert.spy(reqspy).called_with(n)
            package.preload[n] = nil
            package.loaded[n] = nil
        end
    end)
end)
