vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lz = require("lze")
local loader = require("lze.c.loader")
local test = ...

test("lze.state returns correct initial length", function()
    ok(0 == #lz.state, "initial state length is 0")
    lz.load({
        {
            "neorgblahblahblah",
            lazy = true,
        },
    })
    ok(1 == #lz.state, "state length is 1 after load")
end)

test("Loading list of plugin specs triggers load on appropriate events", function()
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
    ok(1 == #spy_load.called, "plugin loaded on startup")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "toml" })
    ok(2 == #spy_load.called, "plugin loaded on filetype event")
    vim.cmd.Telescope()
    ok(3 == #spy_load.called, "plugin loaded on command")
    spy_load.off()
end)

test("Loading individual plugin specs works correctly", function()
    local spy_load = spy.on(loader, "load")
    lz.load({
        "foo.nvim",
        keys = "<leader>ff",
    })
    ok(0 == #spy_load.called, "plugin not loaded initially")
    local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>ff", true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(1 == #spy_load.called, "plugin loaded after keypress")
    lz.load({
        "bar.nvim",
        cmd = "Bar",
    })
    vim.cmd.Bar()
    ok(2 == #spy_load.called, "plugin loaded after command")
    spy_load.off()
end)

test("Custom load function can be specified in plugin spec", function()
    local loaded = false
    lz.load({
        "baz.nvim",
        keys = "<leader>bb",
        load = function()
            loaded = true
        end,
    })
    ok(false == loaded, "custom load function not called initially")
    local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>bb", true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(true == loaded, "custom load function called after keypress")
end)

test("Loading list with single plugin spec works correctly", function()
    local spy_load = spy.on(loader, "load")
    lz.load({
        {
            "single.nvim",
            cmd = "Single",
        },
    })
    ok(0 == #spy_load.called, "plugin not loaded initially")
    pcall(vim.cmd.Single)
    ok(1 == #spy_load.called, "plugin loaded after command")
    spy_load.off()
end)

test("Plugin specs can be disabled via enabled field", function()
    lz.load({
        "fool.nvim",
        keys = "<leader>ff",
        enabled = false,
    })
    ok(nil == lz.state("fool.nvim"), "disabled plugin has nil state")
    lz.load({
        "bard.nvim",
        enabled = function()
            return false
        end,
    })
    ok(nil == lz.state("bard.nvim"), "plugin with false function has nil state")
    local checked = 0
    lz.load({
        "barz.nvim",
        lazy = true,
        enabled = function()
            if checked == 0 then
                checked = checked + 1
                return true
            elseif checked == 1 then
                checked = checked + 1
                return false
            elseif checked == 2 then
                checked = checked + 1
                ---@diagnostic disable-next-line: return-type-mismatch
                return nil
            else
                return true
            end
        end,
    })
    ok("table" == type(lz.state["barz.nvim"]), "plugin with enabled=true has table state")
    lz.trigger_load("barz.nvim")
    ok("table" == type(lz.state["barz.nvim"]), "plugin still has table state after first trigger")
    lz.trigger_load("barz.nvim")
    ok("table" == type(lz.state["barz.nvim"]), "plugin still has table state after second trigger")
    lz.trigger_load("barz.nvim")
    ok(false == lz.state("barz.nvim"), "plugin removed from state after third trigger")
end)

test("Errors in startup plugins don't stop other plugins from loading", function()
    local spy_load = spy.on(loader, "load")
    pcall(lz.load, {
        {
            "rustyness",
            load = function()
                error("I shouldn't break anything")
            end,
        },
        {
            "create",
        },
        {
            "noscope.nvim",
        },
    })
    ok(3 == #spy_load.called, "all plugins loaded despite error in one")
    spy_load.off()
end)
