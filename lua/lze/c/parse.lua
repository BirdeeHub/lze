-- needed so we can use stuff defined later in the file
local lib = {}

---@param spec lze.SpecImport
local function is_disabled(spec)
    return spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
end

---@param spec lze.SpecImport
---@param result lze.Plugin[]
local function import_spec(spec, result)
    if is_disabled(spec) then
        return
    end
    if type(spec.import) == "table" then
        ---@diagnostic disable-next-line: param-type-mismatch
        lib.normalize(spec.import, result)
        return
    end
    if type(spec.import) ~= "string" then
        vim.schedule(function()
            vim.notify(
                "Invalid import spec. The 'import' field should be a module name (or more specs), but was instead: "
                    .. vim.inspect(spec),
                vim.log.levels.ERROR,
                { title = "lze" }
            )
        end)
        return
    end
    local modname = spec.import
    local ok, mod = pcall(require, modname)
    if not ok then
        vim.schedule(function()
            local err = type(mod) == "string" and "': " .. mod or ""
            vim.notify("Failed to load module '" .. modname .. err, vim.log.levels.ERROR, { title = "lze" })
        end)
        return
    end
    if type(mod) ~= "table" then
        vim.schedule(function()
            vim.notify(
                "Invalid plugin spec module '" .. modname .. "' of type '" .. type(mod) .. "'",
                vim.log.levels.ERROR,
                { title = "lze" }
            )
        end)
        return
    end
    lib.normalize(mod, result)
end

---@param spec lze.Spec
---@return boolean
local function is_spec_list(spec)
    return #spec > 1 or vim.islist(spec) and #spec > 1 or #spec == 1 and type(spec[1]) == "table"
end

---@param spec lze.Spec
---@return boolean
local function is_single_plugin_spec(spec)
    ---@diagnostic disable-next-line: undefined-field
    return type(spec[1]) == "string" or type(spec.name) == "string"
end

---@param spec lze.Spec
---@param result lze.Plugin[]
function lib.normalize(spec, result)
    if is_spec_list(spec) then
        for _, sp in ipairs(spec) do
            ---@cast sp lze.Spec
            lib.normalize(sp, result)
        end
    elseif is_single_plugin_spec(spec) then
        ---@diagnostic disable-next-line: inject-field
        spec.name = spec.name or spec[1]
        spec[1] = nil
        if type(spec) == "table" and type(spec.name) == "string" then
            table.insert(result, spec)
        else
            vim.schedule(function()
                vim.notify(
                    "attempted to add a plugin with no name: " .. vim.inspect(spec),
                    vim.log.levels.ERROR,
                    { title = "lze" }
                )
            end)
        end
    elseif spec.import then
        ---@cast spec lze.SpecImport
        import_spec(spec, result)
    end
end

---@param spec lze.Spec
---@return lze.Plugin[]
return function(spec)
    local result = {}
    lib.normalize(spec, result)
    return result
end
