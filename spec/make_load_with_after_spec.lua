local lze = require("lze")
describe("lze.make_load_with_after", function()
    package.preload["lze.test.plugin.function"] = function()
        local M = {}
        ---@type string[]
        M.loaded = {}
        M.run_test_func = function(dirname)
            table.insert(M.loaded, dirname)
        end
        return M
    end
    local test_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
    local test_packpath = test_dir .. "/test_packpath"
    local load_with_after = lze.make_load_with_after({ "plugin" })
    local load_with_after_2 = lze.make_load_with_after({ "plugin" }, function(name)
        local pluginpath = test_dir .. "/" .. name
        dofile(pluginpath .. "/plugin/testplug.lua")
        return pluginpath
    end)
    it("should return a function", function()
        assert.is_function(load_with_after)
        assert.is_function(load_with_after_2)
    end)
    it("test with custom load function", function()
        load_with_after_2("test_plugin")
        assert.True(vim.tbl_contains(require("lze.test.plugin.function").loaded, "plugin"))
        assert.True(vim.tbl_contains(require("lze.test.plugin.function").loaded, "after/plugin"))
        require("lze.test.plugin.function").loaded = {}
    end)
    it("test without custom load function", function()
        vim.opt.runtimepath:append(test_packpath)
        vim.opt.packpath:append(test_packpath)
        load_with_after("test_plugin_pack")
        assert.True(vim.tbl_contains(require("lze.test.plugin.function").loaded, "plugin"))
        assert.True(vim.tbl_contains(require("lze.test.plugin.function").loaded, "after/plugin"))
        require("lze.test.plugin.function").loaded = {}
        vim.opt.runtimepath:remove(test_packpath)
        vim.opt.packpath:remove(test_packpath)
    end)
end)
