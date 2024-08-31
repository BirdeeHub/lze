local lz = require("lze")
vim.g.lze = {
    load = function() end,
}
local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir .. "/lua/plugins" }):wait()

local loader = require("lze.c.loader")
local spy = require("luassert.spy")

describe("lze", function()
    describe("load", function()
        it("import", function()
            local plugin_config_content = [[
        return {
          "baz.nvim",
          cmd = "Baz",
        }
        ]]
            local spec_file = vim.fs.joinpath(tempdir, "lua", "plugins", "init.lua")
            local fh = assert(io.open(spec_file, "w"), "Could not open config file for writing")
            fh:write(plugin_config_content)
            fh:close()
            vim.opt.runtimepath:append(tempdir)
            local spy_load = spy.on(loader, "load")
            lz.load("plugins")
            vim.cmd.Baz()
            assert.spy(spy_load).called(1)
            vim.system({ "rm", spec_file }):wait()
            package.loaded["plugins"] = nil
        end)
        it("import root file", function()
            local plugin_config_content = [[
        return {
            { "cuteify.nvim" },
            { "bat.nvim", cmd = "Bat" },
        }
        ]]
            local plugin1_spec_file = vim.fs.joinpath(tempdir, "lua", "plugins.lua")
            local fh = assert(io.open(plugin1_spec_file, "w"), "Could not open config file for writing")
            fh:write(plugin_config_content)
            fh:close()
            vim.opt.runtimepath:append(tempdir)
            local spy_load = spy.on(loader, "load")
            lz.load("plugins")
            assert.spy(spy_load).called(1)
            vim.cmd.Bat()
            assert.spy(spy_load).called(2)
            vim.system({ "rm", plugin1_spec_file }):wait()
            package.loaded["plugins"] = nil
        end)
        it("import plugin specs and spec file", function()
            local plugins_dir = vim.fs.joinpath(tempdir, "lua", "plugins")
            local plugin1_config_content = [[
return {
  "telescope.nvim",
  cmd = "Telescope",
  after = function()
    vim.g.telescope_after = true
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
    "foo.nvim",
    cmd = "Foo",
    after = function()
      vim.g.foo_after = true
    end,
  },
  { import = "plugins.telescope", },
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
                { import = "plugins.foo" },
                { "sweetie.nvim" },
            })
            assert.spy(spy_load).called(1)
            vim.cmd.Telescope()
            assert.spy(spy_load).called(2)
            assert.True(vim.g.telescope_after)
            vim.cmd.Foo()
            assert.spy(spy_load).called(3)
            assert.True(vim.g.foo_after)
            -- vim.cmd.Linked()
            -- assert.spy(spy_load).called(4)
            vim.system({ "rm", plugin2_spec_file }):wait()
            package.loaded["plugins"] = nil
        end)
    end)
end)
