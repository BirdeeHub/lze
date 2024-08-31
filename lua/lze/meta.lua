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

---@class lze.PluginHooks
---
---Will be run before loading any plugins in that require('lze').load() call
---@field beforeAll? fun(self:lze.Plugin)
---
---Will be run before loading this plugin
---@field before? fun(self:lze.Plugin)
---
---Will be executed after loading this plugin
---@field after? fun(self:lze.Plugin)

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
---@field [1] string lhs
---@field [2]? string|fun()|false rhs
---@field mode? string|string[]

---@class lze.Keys: lze.KeysBase
---@field lhs string lhs
---@field rhs? string|fun() rhs
---@field mode? string
---@field id string
---@field name string

---@alias lze.Event {id:string, event:string[]|string, pattern?:string[]|string}
---@alias lze.EventSpec string|{event?:string|string[], pattern?:string|string[]}|string[]

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

---@class lze.ExtraSpecHandlers
---
---Load a plugin after load of one or more other plugins.
---@field on_plugin? string[]|string
---
---Accepts a top-level lua module name or a
---list of top-level lua module names.
---Will load when any submodule of those listed is `require`d
---@field on_require? string[]|string

-- NOTE:
-- Defintion of lze.Plugin and lze.PluginSpec
-- combining above types.

---Internal lze.Plugin type, after being parsed.
---Is the type passed to handlers in modify and add hooks.
---@class lze.Plugin: lze.PluginBase,lze.PluginHooks,lze.SpecHandlers, lze.ExtraSpecHandlers
---The plugin name (not its main module), e.g. "sweetie.nvim"
---@field name string
---
---Whether to lazy-load this plugin. Defaults to `false`.
---@field lazy? boolean

---The lze.PluginSpec type, passed to require('lze').load() as entries in lze.Spec
---@class lze.PluginSpec: lze.PluginBase,lze.PluginHooks,lze.SpecHandlers, lze.ExtraSpecHandlers
---The plugin name (not its main module), e.g. "sweetie.nvim"
---@field [1] string

---@class lze.SpecImport
---@field import string spec module to import
---@field enabled? boolean|(fun():boolean)

---List of lze.PluginSpec and/or lze.SpecImport
---@alias lze.Spec lze.PluginSpec | lze.SpecImport | lze.Spec[]

-- NOTE:
-- lze.Handler type definition

---Listed in the order they are called by lze if the handler has been registered
---@class lze.Handler
---@field spec_field string
---@field modify? fun(plugin: lze.Plugin): lze.Plugin
---@field add? fun(plugin: lze.Plugin)
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
---Callback to load a plugin.
---Takes the plugin name (not the module name). Defaults to |packadd| if not set.
---@field load? fun(name: string)
---
---If false, lze will print error messages on fewer things.
---@field verbose? boolean

---@type lze.Config
vim.g.lze = vim.g.lze
