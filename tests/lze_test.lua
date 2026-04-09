vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lz = require("lze")
local loader = require("lze.c.loader")
local test = ...

test("lze load __len works", function()
    ok(0 == #lz.state, "initial state length is 0")
    lz.load({
        {
            "neorgblahblahblah",
            lazy = true,
        },
    })
    ok(1 == #lz.state, "state length is 1 after load")
end)

test("lze load list of plugin specs", function()
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
    ok(1 == #spy_load.called, "load called once")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "toml" })
    ok(2 == #spy_load.called, "load called twice")
    vim.cmd.Telescope()
    ok(3 == #spy_load.called, "load called three times")
    spy_load.off()
end)

test("lze load individual plugin specs", function()
    local spy_load = spy.on(loader, "load")
    lz.load({
        "foo.nvim",
        keys = "<leader>ff",
    })
    ok(0 == #spy_load.called, "load not called initially")
    local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>ff", true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(1 == #spy_load.called, "load called after keypress")
    lz.load({
        "bar.nvim",
        cmd = "Bar",
    })
    vim.cmd.Bar()
    ok(2 == #spy_load.called, "load called after cmd")
    spy_load.off()
end)

test("lze load can override load implementation via plugin spec", function()
    local loaded = false
    lz.load({
        "baz.nvim",
        keys = "<leader>bb",
        load = function()
            loaded = true
        end,
    })
    ok(false == loaded, "loaded is false initially")
    local feed = vim.api.nvim_replace_termcodes("<Ignore><leader>bb", true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(true == loaded, "loaded is true after keypress")
end)

test("lze load list with a single plugin spec", function()
    local spy_load = spy.on(loader, "load")
    lz.load({
        {
            "single.nvim",
            cmd = "Single",
        },
    })
    ok(0 == #spy_load.called, "load not called initially")
    pcall(vim.cmd.Single)
    ok(1 == #spy_load.called, "load called after cmd")
    spy_load.off()
end)

test("lze load can disable plugin specs as specified", function()
    lz.load({
        "fool.nvim",
        keys = "<leader>ff",
        enabled = false,
    })
    ok(nil == lz.state("fool.nvim"), "fool.nvim state is nil")
    lz.load({
        "bard.nvim",
        enabled = function()
            return false
        end,
    })
    ok(nil == lz.state("bard.nvim"), "bard.nvim state is nil")
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
    ok("table" == type(lz.state["barz.nvim"]), "barz.nvim state is table")
    lz.trigger_load("barz.nvim")
    ok("table" == type(lz.state["barz.nvim"]), "barz.nvim state is table after trigger")
    lz.trigger_load("barz.nvim")
    ok("table" == type(lz.state["barz.nvim"]), "barz.nvim state is table after 2nd trigger")
    lz.trigger_load("barz.nvim")
    ok(false == lz.state("barz.nvim"), "barz.nvim state is false after 3rd trigger")
end)

test("lze load handles errors in startup plugins without stopping", function()
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
    ok(3 == #spy_load.called, "load called 3 times despite error")
    spy_load.off()
end)
