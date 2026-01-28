---@meta
error("Cannot import a meta module")

---@class lze.PluginBase
---
---Whether to enable this plugin. Useful to disable plugins under certain conditions.
---@field enabled? boolean|(fun():boolean)
---
---Only useful for lazy=false plugins to force loading certain plugins first.
---Default priority is 50
---@field priority? number
---
---Set this to override the `load` function for an individual plugin.
---Defaults to `vim.g.lze.load()`, see |lze.Config|.
---@field load? fun(name: string)
---
---True will allow a plugin to be added to the queue again after it has already been triggered.
---@field allow_again? boolean
---
---Will be run before loading any plugins in that require('lze').load() call
---@field beforeAll? fun(self:lze.Plugin)
---
---Will be run before loading this plugin
---@field before? fun(self:lze.Plugin)
---
---Will be executed after loading this plugin
---@field after? fun(self:lze.Plugin)
---
---Whether to lazy-load this plugin. Defaults to `false`.
---Using a handler's field sets this automatically.
---@field lazy? boolean

-- NOTE:
-- Builtin Handler Types:

---@class lze.KeysBase: vim.keymap.set.Opts
---@field desc? string
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field nowait? boolean
---@field ft? string|string[]

---@class lze.KeysSpec: lze.KeysBase
---@field [1]? string [1] or lhs required, [1] wins
---@field [2]? string|fun()|false will override rhs
---@field lhs? string [1] or lhs required, [1] wins
---@field rhs? string|fun()|false [2] will override rhs if set
---@field mode? string|string[]

---@class lze.Keys: lze.KeysBase
---@field lhs string lhs
---@field rhs? string|fun() rhs
---@field mode? string
---@field id string
---@field name string

---@alias lze.Event {id:string, event:string[]|string, pattern?:string[]|string, augroup:integer}
---@alias lze.EventSpec string|{event?:string|string[], pattern?:string|string[], augroup?:integer}|string[]

---@class lze.SpecHandlers
---
---Load a plugin on one or more |autocmd-events|.
---@field event? string|lze.EventSpec[]
---
---Load a plugin on one or more |user-commands|.
---@field cmd? string[]|string
---
---Load a plugin on one or more |FileType| events.
---@field ft? string[]|string
---
---Load a plugin on one or more |key-mapping|s.
---@field keys? string|string[]|lze.KeysSpec[]
---
---Load a plugin on one or more |colorscheme| events.
---@field colorscheme? string[]|string
---
---Load a plugin before load of one or more other plugins.
---@field dep_of? string[]|string
---
---Load a plugin after load of one or more other plugins.
---@field on_plugin? string[]|string
---
---Accepts a top-level lua module name or a
---list of top-level lua module names.
---Will load when any submodule of those listed is `require`d
---@field on_require? string[]|string
---
---@field [string] any? Fields for any extra handlers you might add

-- NOTE:
-- Defintion of lze.Plugin and lze.PluginSpec
-- combining above types.

---Internal lze.Plugin type, after being parsed.
---Is the type passed to handlers in modify and add hooks.
---@class lze.Plugin: lze.PluginBase,lze.SpecHandlers
---The plugin name (not its main module), e.g. "sweetie.nvim"
---@field name string

---The lze.PluginSpec type, passed to require('lze').load() as entries in lze.Spec
---@class lze.PluginSpec: lze.PluginBase,lze.SpecHandlers
---The plugin name (not its main module), e.g. "sweetie.nvim"
---@field [1] string

---@class lze.SpecImport
---@field import string|lze.Spec|(fun():lze.Spec) spec module to import
---@field enabled? boolean|(fun():boolean)

---List of lze.PluginSpec and/or lze.SpecImport
---@alias lze.Spec lze.PluginSpec | lze.Plugin | lze.SpecImport | lze.Spec[]

-- NOTE:
-- lze.Handler type definition

---Listed in the order they are called by lze if the handler has been registered
---@class lze.Handler
---@field spec_field string
---
---Your handler's 1 chance to modify plugins before they are entered into state!
---Called only if your field was present.
---@field modify? fun(plugin: lze.Plugin): lze.Plugin, fun()?
---
---Called after being entered into state but before any loading has occurred
---@field add? fun(plugin: lze.Plugin): fun()?
---
---Whether using this handler's field should have an effect on the lazy setting
---True or nil is true
---Default: nil
---@field set_lazy? boolean
---
---Handlers may export functions and other values via this set,
---which then may be accessed via `require('lze').h[spec_field].your_func()`
---@field lib? table
---Called when the handler is registered
---@field init? fun()
---Allows you to clean up any global modifications your handler makes to the environment.
---@field cleanup? fun()
---
---runs at the end of require('lze').load()
---for handlers to set up extra triggers such as the
---event handler's DeferredUIEnter event
---@field post_def? fun()
---
---Plugin's before will run first
---@field before? fun(name: string)
---Plugin's load will run here
---@field after? fun(name: string)
---Plugin's after will run after

---Optional, for passing to register_handlers,
---if easily changing if a handler gets added or not is desired
---@class lze.HandlerSpec
---@field handler lze.Handler
---@field enabled? boolean|(fun():boolean)

-- NOTE:
-- global vim.g.lze config values table

---@class lze.Config
---
---Default callback used to load a plugin.
---Takes the plugin name (not the module name). Defaults to |packadd| if not set.
---Not provided to handler hooks
---@field load? fun(name: string)
---
---Allows you to inject a default value
---for any non-nil plugin spec field
---which will be visible to all handler hooks.
---@field injects? table
---
---If false, lze will print error messages on fewer things.
---@field verbose? boolean
---
---Default priority for startup plugins. Defaults to 50 if unset
---@field default_priority? integer
---
---If true, lze will not automatically register the default handlers.
---@field without_default_handlers? boolean

---@type lze.Config
vim.g.lze = vim.g.lze
