local lze = require("lze")
local test = ...
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
test("Require handler loads plugin when module is required", function()
    local reqspy = spy(dummy)
    local loadspy = spy(dummy)
    local mktestplug = mkmktestplug(loadspy, reqspy)
    local name = "lze_test_require_mod"
    ---@type lze.Plugin
    lze.load(mktestplug(name))
    require(name)
    ok(name == loadspy.called[1][1], "load hook called with correct module name")
    ok(name == reqspy.called[1][1], "require hook called with correct module name")
    package.preload[name] = nil
    package.loaded[name] = nil
end)

test("Require handler handles nested plugin dependencies", function()
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
    ok(name3 == require(name3), "module can be required successfully")
    local function find_call(spy_tbl, search_name)
        for _, call in ipairs(spy_tbl.called) do
            if call[1] == search_name then
                return true
            end
        end
        return false
    end
    for _, n in ipairs({ name, name2, name3 }) do
        ok(find_call(loadspy, n), "load hook called for " .. n)
        ok(find_call(reqspy, n), "require hook called for " .. n)
        package.preload[n] = nil
        package.loaded[n] = nil
    end
end)
