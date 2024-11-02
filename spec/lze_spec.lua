local lz = require("lze")
vim.g.lze = {
    load = function() end,
}
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("lze", function()
    describe("load", function()
        it("list of plugin specs", function()
            local spy_load = spy.on(loader, "load")
            lz.load({
                {
                    "neorg",
                },
                {
                    "crates.nvim",
                    ft = { "toml", "rust" },
                },
                {
                    "telescope.nvim",
                    keys = { { "<leader>tt", mode = { "n", "v" } } },
                    cmd = "Telescope",
                },
            })
            assert.spy(spy_load).called(1)
            assert.spy(spy_load).called_with("neorg")
            vim.api.nvim_exec_autocmds("FileType", { pattern = "toml" })
            assert.spy(spy_load).called(2)
            assert.spy(spy_load).called_with({ "crates.nvim" })
            vim.cmd.Telescope()
            assert.spy(spy_load).called(3)
            assert.spy(spy_load).called_with({ "telescope.nvim" })
        end)
        it("individual plugin specs", function()
            local spy_load = spy.on(loader, "load")
            lz.load({
                "foo.nvim",
                keys = "<leader>ff",
            })
            assert.spy(spy_load).called(0)
            local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>ff", true, true, true)
            vim.api.nvim_feedkeys(feed, "ix", false)
            assert.spy(spy_load).called(1)
            lz.load({
                "bar.nvim",
                cmd = "Bar",
            })
            vim.cmd.Bar()
            assert.spy(spy_load).called(2)
        end)
        it("can override load implementation via plugin spec", function()
            local loaded = false
            lz.load({
                "baz.nvim",
                keys = "<leader>bb",
                load = function()
                    loaded = true
                end,
            })
            assert.False(loaded)
            local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>bb", true, true, true)
            vim.api.nvim_feedkeys(feed, "ix", false)
            assert.True(loaded)
        end)
        it("list with a single plugin spec", function()
            local spy_load = spy.on(loader, "load")
            lz.load({
                {
                    "single.nvim",
                    cmd = "Single",
                },
            })
            assert.spy(spy_load).called(0)
            pcall(vim.cmd.Single)
            assert.spy(spy_load).called(1)
            assert.spy(spy_load).called_with({ "single.nvim" })
        end)
        it("can disable plugin specs as specified", function()
            lz.load({
                "fool.nvim",
                keys = "<leader>ff",
                enabled = false,
            })
            assert(lz.state("fool.nvim") == nil)
            lz.load({
                "bard.nvim",
                enabled = function(_)
                    return false
                end,
            })
            assert(lz.state("bard.nvim") == nil)
            local checked = 0
            lz.load({
                "barz.nvim",
                lazy = true,
                enabled = function(_)
                    if checked == 0 then
                        checked = checked + 1
                        return true
                    elseif checked == 1 then
                        checked = checked + 1
                        return false
                    elseif checked == 2 then
                        checked = checked + 1
                        return nil
                    else
                        return true
                    end
                end,
            })
            assert(type(lz.state["barz.nvim"]) == "table")
            lz.trigger_load("barz.nvim")
            assert(type(lz.state["barz.nvim"]) == "table")
            lz.trigger_load("barz.nvim")
            assert(type(lz.state["barz.nvim"]) == "table")
            lz.trigger_load("barz.nvim")
            assert(lz.state("barz.nvim") == false)
        end)
    end)
end)
