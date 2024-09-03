describe("nested events", function()
    it("lazy-loaded colorscheme triggered by UIEnter event", function()
        require("lze").load({
            {
                "sick_colorscheme_bruh.nvim",
                colorscheme = "sick_colorscheme_bruh",
                load = function()
                    vim.g.sweetie_nvim_loaded = true
                end,
            },
            {
                "xyzhghjggjh",
                event = "UIEnter",
                after = function()
                    pcall(vim.cmd.colorscheme, "sick_colorscheme_bruh")
                end,
                load = function() end,
            },
        })
        vim.api.nvim_exec_autocmds("UIEnter", {})
        assert.True(vim.g.sweetie_nvim_loaded)
    end)
end)
