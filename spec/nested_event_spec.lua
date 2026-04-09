local test = require("gambiarra")
test("nested events lazy-loaded colorscheme triggered by UIEnter event", function()
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
            load = function()
                vim.g.event_nested_works = true
            end,
        },
    })
    vim.api.nvim_exec_autocmds("UIEnter", {})
    ok(true == vim.g.event_nested_works, "event_nested_works is true")
    ok(true == vim.g.sweetie_nvim_loaded, "sweetie_nvim_loaded is true")
end)
