-- needed so we can use normalize in import_spec even if its defined later in the file
local __f__ = {}

-- It turns out that its faster when you copy paste
-- Would be nice to just define it
-- once, but then you lose 10ms
---@param spec lze.Plugin|lze.HandlerSpec|lze.SpecImport
local function is_enabled(spec)
    local disabled = spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled())
    return not disabled
end

---@param spec lze.SpecImport
---@param result lze.Plugin[]
local function import_spec(spec, result)
    if type(spec.import) ~= "string" then
        vim.schedule(function()
            vim.notify(
                "Invalid import spec. The 'import' field should be a module name: " .. vim.inspect(spec),
                vim.log.levels.ERROR,
                { title = "lze" }
            )
        end)
        return
    end
    if not is_enabled(spec) then
        return
    end
    local modname = spec.import
    local ok, mod = pcall(require, modname)
    if not ok then
        vim.schedule(function()
            local err = type(mod) == "string" and ": " .. mod or ""
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
    __f__.normalize(mod, result)
end

---@param spec lze.PluginSpec
---@return lze.Plugin
local function parse(spec)
    ---@type lze.Plugin
    ---@diagnostic disable-next-line: inject-field
    spec.name = spec.name or spec[1]
    spec[1] = nil
    ---@diagnostic disable-next-line: inject-field
    spec.lazy = require("lze.c.handler").is_lazy(spec)
    local result = require("lze.c.handler").run_modify(spec)
    return vim.deepcopy(result)
end

---XXX: This is unsafe because we assume a prior `vim.islist` check
---
---@param spec lze.Spec
---@return boolean
local function is_list_with_single_spec_unsafe(spec)
    return #spec == 1 and type(spec[1]) == "table"
end

---@param spec lze.Spec
---@return boolean
local function is_spec_list(spec)
    return #spec > 1 or vim.islist(spec) and #spec > 1 or is_list_with_single_spec_unsafe(spec)
end

---@param spec lze.Spec
---@return boolean
local function is_single_plugin_spec(spec)
    ---@diagnostic disable-next-line: undefined-field
    return type(spec[1]) == "string" or type(spec.name) == "string"
end

---@private
---@param spec lze.Spec
---@param result lze.Plugin[]
function __f__.normalize(spec, result)
    if is_spec_list(spec) then
        for _, sp in ipairs(spec) do
            ---@cast sp lze.Spec
            __f__.normalize(sp, result)
        end
    elseif is_single_plugin_spec(spec) then
        ---@cast spec lze.PluginSpec
        local parsed = parse(spec)
        if type(parsed) == "table" and type(parsed.name) == "string" then
            if is_enabled(parsed) then
                table.insert(result, parsed)
            end
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

local M = {}

---@param spec lze.Spec
---@return lze.Plugin[]
function M.parse(spec)
    local result = {}
    __f__.normalize(spec, result)
    return result
end

return M
