---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("handlers.cmd", function()
    it("Command only loads plugin once and executes plugin command", function()
        local counter = 0
        ---@type lze.Plugin
        local plugin = {
            name = "foos",
            cmd = { "Foos" },
            after = function()
                vim.api.nvim_create_user_command("Foos", function()
                    counter = counter + 1
                end, {})
            end,
        }
        local spy_load = spy.on(loader, "load")
        lze.load({ plugin })
        assert.is_not_nil(vim.cmd.Foos)
        vim.cmd.Foos()
        vim.cmd.Foos()
        assert.spy(spy_load).called(1)
        assert.same(2, counter)
    end)
    it("Multiple commands only load plugin once", function()
        ---@param commands string[]
        local function itt(commands, name)
            ---@type lze.Plugin
            local plugin = {
                name = name,
                cmd = commands,
                after = function()
                    vim.api.nvim_create_user_command(commands[1], function() end, {})
                    vim.api.nvim_create_user_command(commands[2], function() end, {})
                end,
            }
            local spy_load = spy.on(loader, "load")
            lze.load({ plugin })
            vim.cmd[commands[1]]()
            vim.cmd[commands[2]]()
            assert.spy(spy_load).called(1)
        end
        itt({ "Foo", "Bar" }, "foo5")
        itt({ "Bar", "Foo" }, "foo4")
    end)
end)
