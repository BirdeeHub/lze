vim.g.lze = {
    injects = {
        load = function() end,
    },
}
local lz = require("lze")
local tempdir = vim.fn.tempname()
local test = ...
vim.system({ "mkdir", "-p", tempdir .. "/lua/plugins" }):wait()

local loader = require("lze.c.loader")

test("lze load import from spec", function()
    lz.load({
        {
            import = {
                {
                    "TESTPLUGIN_IMPORT_FROM_SPEC",
                    lazy = true,
                },
            },
        },
    })
    ok(true == lz.state("TESTPLUGIN_IMPORT_FROM_SPEC"), "plugin loaded initially")
    lz.trigger_load("TESTPLUGIN_IMPORT_FROM_SPEC")
    ok(false == lz.state("TESTPLUGIN_IMPORT_FROM_SPEC"), "plugin unloaded after trigger")
end)

test("lze load import", function()
    local plugin_config_content = [[
        return {
          "import_test_baz.nvim",
          cmd = "ImportTestBaz",
        }
        ]]
    local spec_dir = vim.fs.joinpath(tempdir, "lua", "import_test_plugins")
    vim.system({ "mkdir", "-p", spec_dir }):wait()
    local spec_file = vim.fs.joinpath(spec_dir, "init.lua")
    local fh = assert(io.open(spec_file, "w"), "Could not open config file for writing")
    fh:write(plugin_config_content)
    fh:close()
    vim.opt.runtimepath:append(tempdir)
    local spy_load = spy.on(loader, "load")
    lz.load("import_test_plugins")
    vim.cmd.ImportTestBaz()
    ok(1 == #spy_load.called, "load called once")
    vim.system({ "rm", spec_file }):wait()
    package.loaded["import_test_plugins"] = nil
    spy_load.off()
end)

test("lze load import root file", function()
    local plugin_config_content = [[
        return {
            { "import_test_cuteify.nvim" },
            { "import_test_bat.nvim", cmd = "ImportTestBat" },
        }
        ]]
    local plugin1_spec_file = vim.fs.joinpath(tempdir, "lua", "import_test_plugins_root.lua")
    local fh = assert(io.open(plugin1_spec_file, "w"), "Could not open config file for writing")
    fh:write(plugin_config_content)
    fh:close()
    vim.opt.runtimepath:append(tempdir)
    local spy_load = spy.on(loader, "load")
    lz.load("import_test_plugins_root")
    ok(1 == #spy_load.called, "load called once")
    vim.cmd.ImportTestBat()
    ok(2 == #spy_load.called, "load called twice")
    vim.system({ "rm", plugin1_spec_file }):wait()
    package.loaded["import_test_plugins_root"] = nil
    spy_load.off()
end)

test("lze load import plugin specs and spec file", function()
    local plugins_dir = vim.fs.joinpath(tempdir, "lua", "import_test_plugins_dir")
    vim.system({ "mkdir", "-p", plugins_dir }):wait()
    local plugin1_config_content = [[
return {
  "import_test_telescope.nvim",
  cmd = "ImportTestTelescope",
  after = function()
    vim.g.import_test_telescope_after = true
  end,
}
]]
    local spec_file = vim.fs.joinpath(plugins_dir, "telescope.lua")
    local fh = assert(io.open(spec_file, "w"), "Could not open config file for writing")
    fh:write(plugin1_config_content)
    fh:close()
    local plugin2_config_content = [[
return {
  {
    "import_test_foo.nvim",
    cmd = "ImportTestFoo",
    after = function()
      vim.g.import_test_foo_after = true
    end,
  },
  { import = "import_test_plugins_dir.telescope", },
}
]]
    local plugin2_dir = vim.fs.joinpath(plugins_dir, "foo")
    vim.system({ "mkdir", "-p", plugin2_dir }):wait()
    local plugin2_spec_file = vim.fs.joinpath(plugin2_dir, "init.lua")
    fh = assert(io.open(plugin2_spec_file, "w"), "Could not open config file for writing")
    fh:write(plugin2_config_content)
    fh:close()
    vim.opt.runtimepath:append(tempdir)
    local spy_load = spy.on(loader, "load")
    lz.load({
        { import = "import_test_plugins_dir.foo" },
        { "import_test_sweetie.nvim" },
    })
    ok(1 == #spy_load.called, "load called once")
    vim.cmd.ImportTestTelescope()
    ok(2 == #spy_load.called, "load called twice")
    ok(true == vim.g.import_test_telescope_after, "telescope after triggered")
    vim.cmd.ImportTestFoo()
    ok(3 == #spy_load.called, "load called three times")
    ok(true == vim.g.import_test_foo_after, "foo after triggered")
    vim.system({ "rm", plugin2_spec_file }):wait()
    package.loaded["import_test_plugins_dir.foo"] = nil
    package.loaded["import_test_plugins_dir.telescope"] = nil
    spy_load.off()
end)
test("import_test cleanup", function(next)
    vim.system({ "rm", "-r", tempdir }):wait()
    -- this seemed also like a good place to make the tests wait until everything is done printing
    vim.schedule(function()
        vim.schedule(next)
    end)
end, true)
