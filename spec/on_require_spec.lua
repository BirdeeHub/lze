local lze = require("lze")
local test = require("gambiarra")
local dummy = function(name)
    return name
end
local function mkmktestplug(loadspy, reqspy)
    return function(name, target)
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
end
test("handlers.on_require require loads plugins", function()
    local reqspy = spy(dummy)
    local loadspy = spy(dummy)
    local mktestplug = mkmktestplug(loadspy, reqspy)
    local name = "lze_test_require_mod"
    ---@type lze.Plugin
    lze.load(mktestplug(name))
    require(name)
    ok(eq(name, loadspy.called[1][1]), "loadspy called with name")
    ok(eq(name, reqspy.called[1][1]), "reqspy called with name")
    package.preload[name] = nil
    package.loaded[name] = nil
end)

test("handlers.on_require handles nested plugins", function()
    local reqspy = spy(dummy)
    local loadspy = spy(dummy)
    local mktestplug = mkmktestplug(loadspy, reqspy)
    local name = "lze_test_require_mod_1"
    local name2 = "lze_test_require_mod_2"
    local name3 = "lze_test_require_mod_3"
    ---@type lze.Plugin
    lze.load({
        mktestplug(name),
        mktestplug(name2, name),
        mktestplug(name3, name2),
    })
    ok(eq(name3, require(name3)), "name3 equals require(name3)")
    local function find_call(spy_tbl, search_name)
        for _, call in ipairs(spy_tbl.called) do
            if call[1] == search_name then
                return true
            end
        end
        return false
    end
    for _, n in ipairs({ name, name2, name3 }) do
        ok(find_call(loadspy, n), "loadspy called with " .. n)
        ok(find_call(reqspy, n), "reqspy called with " .. n)
        package.preload[n] = nil
        package.loaded[n] = nil
    end
end)
