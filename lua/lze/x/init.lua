vim.schedule(function()
    vim.notify(
        "handlers from lze.x have now been included in lze.h\n"
            .. "You may remove the register_handlers call that added them, as they are now included by default\n"
            .. "require('lze.x') is being deprecated.\n"
            .. "It now does nothing but warn, and will be removed in the future.",
        vim.log.levels.WARN,
        { title = "lze" }
    )
end)
return {}
