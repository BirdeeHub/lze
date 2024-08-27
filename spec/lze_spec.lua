local lz = require("lze")
vim.g.lze = {
    load = function() end,
}
local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("lze", function()
    describe("load", function()
        it("list of plugin specs", function()
            local spy_load = spy.on(loader, "_load")
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
            assert.spy(spy_load).called_with({
                name = "neorg",
                lazy = false,
            })
            vim.api.nvim_exec_autocmds("FileType", { pattern = "toml" })
            assert.spy(spy_load).called(2)
            assert.spy(spy_load).called_with({
                name = "crates.nvim",
                lazy = true,
                ft = { "toml", "rust" },
                event = {
                    {
                        event = "FileType",
                        id = "toml",
                        pattern = "toml",
                    },
                    {
                        event = "FileType",
                        id = "rust",
                        pattern = "rust",
                    },
                },
            })
            vim.cmd.Telescope()
            assert.spy(spy_load).called(3)
            assert.spy(spy_load).called_with({
                name = "telescope.nvim",
                lazy = true,
                cmd = "Telescope",
                keys = { { "<leader>tt", mode = { "n", "v" } } },
            })
        end)
        it("individual plugin specs", function()
            local spy_load = spy.on(loader, "_load")
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
            local spy_load = spy.on(loader, "_load")
            lz.load({
                {
                    "single.nvim",
                    cmd = "Single",
                },
            })
            assert.spy(spy_load).called(0)
            pcall(vim.cmd.Single)
            assert.spy(spy_load).called(1)
            assert.spy(spy_load).called_with({
                name = "single.nvim",
                lazy = true,
                cmd = "Single",
            })
        end)
    end)
end)
