local lze = require("lze")
local spy = require("luassert.spy")

describe("handlers.on_require", function()
    local reqspy = spy.new(function(name)
        return name
    end)
    local loadspy = spy.new(function(name)
        package.preload[name] = function()
            return reqspy(name)
        end
    end)
    local function mktestplug(name, target)
        return {
            name = name,
            on_require = { name },
            load = function(n)
                loadspy(n)
                if target then
                    require(target)
                end
            end,
        }
    end
    it("require loads plugins", function()
        local name = "my_test_req_mod_1"
        ---@type lze.Plugin
        lze.load(mktestplug(name))
        require(name)
        assert.spy(loadspy).called_with(name)
        assert.spy(reqspy).called_with(name)
        package.preload[name] = nil
        package.loaded[name] = nil
    end)
    it("handles nested plugins", function()
        local name = "my_test_req_mod_2"
        local name2 = "my_test_req_mod_3"
        local name3 = "my_test_req_mod_4"
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
