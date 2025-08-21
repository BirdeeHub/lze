<!-- markdownlint-disable MD028 -->
# :sloth: lze

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![LuaRocks][luarocks-shield]][luarocks-url]

A dead simple lazy-loading Lua library for Neovim plugins.

It is intended to be used

- by users of plugin managers that don't provide a convenient API for lazy-loading.
- by plugin managers, to provide a convenient API for lazy-loading.

> What problem does it solve?
If I am downloading a plugin as optional,
can't I call `vim.cmd.packadd` from an autocommand myself to load it?

Yes you can. However, you may wish to trigger a plugin on one of *many* triggers,
rather than just one triggering condition.

You will find that either gets very verbose very quickly,
or results in something like this plugin.

`lze` solves this problem in a simple, performant, and extensible way.

## :question: Is this [`lz.n`](https://github.com/nvim-neorocks/lz.n)?

Nope. I quite like `lz.n`. I have contributed to `lz.n` many times.

`lz.n` is a great plugin.
I think having the handlers manage the entire
state of `lz.n` is an elegant solution.

But it also meant I had to be more careful with state when writing handlers,
or else my plugin may not be properly trigger-able.
`lz.n` to that effect has provided an API to make this easier.

This is my take on `lz.n`.

The core has been entirely rewritten
and it handles its state entirely differently.

It shares some code where some handlers parse their specs,
otherwise it works entirely differently, but
with a largely compatible [plugin spec](#plugin-spec)

However, import specs can only import a
single module rather than a whole directory.

Why?

`lze` actually treats your list of specs as a list.
If your startup plugins have not been given a priority,
they load in the order passed in.

What order should the directory be imported in? I left it up to you.

> Why does the readme say it is a dead simple library?

The core of `lze` is simply a read-only table. You queue up
a plugin, a handler loads it when you tell it to,
it gets replaced with `false`.

Handlers have 1 chance to prevent a plugin from entering,
or modify it before it enters **if active for that spec**,
(none of the default handlers need this).

Once it has been entered,
it will remain there until it has been loaded via
a call to `require('lze').trigger_load(name)` (or a list of names).

You can only add it to the queue again
*after* it has been loaded, and specifically allow it to be added again.

That's basically it. The handlers call
`trigger_load` with some names on some sort of event,
`lze` loads it if its in the table,
and if not, it returns the skipped ones,
by default, warning if it wasn't found at all.

## :star2: Features

- API for lazy-loading plugins on:
  - Events (`:h autocmd-events`)
  - `FileType` events
  - Key mappings
  - User commands
  - Colorscheme events
  - Other plugins
  - whatever you can write a [custom handler](#custom-handlers) for
- Works with:
  - Neovim's built-in `:h packpath` (`:h packadd`)
  - Any plugin manager that supports manually lazy-loading
    plugins by name
- Configurable in multiple files

## :moon: Introduction

`lze` provides abstractions for lazy-loading Neovim plugins,
with an API that is loosely based on [`lazy.nvim`](https://github.com/folke/lazy.nvim),
but reduced down to the very basics required for lazy-loading only.

If attempting lazy loading via autocommands, it can get very verbose
when you wish to load a plugin on multiple triggers.

This greatly simplifies that process, and is easy to extend with
your own custom fields via [custom handlers](#custom-handlers),
the same mechanism through which the builtin handlers are created.

> [!NOTE]
>
> **Should I lazy-load plugins?**
>
> It should be a plugin author's responsibility to ensure their plugin doesn't
> unnecessarily impact startup time, not yours!
>
> See [nvim-neorocks "DO's and DONT's" guide for plugin developers](https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#sleeping_bed-lazy-loading).
>
> Regardless, some authors may not have the capacity
> or knowledge to improve their plugins' startup impact.
>
> If you find a plugin that takes too long to load,
> or worse, forces you to load it manually at startup with a
> call to a heavy `setup` function,
> consider opening an issue on the plugin's issue tracker.

### :milky_way: Philosophy

`lze` is designed based on the UNIX philosophy: Do one thing well.

### :zzz: Comparison with `lazy.nvim`

- `lze` is **not a plugin manager**, but focuses **on lazy-loading only**.
  It is intended to be used with (or by) a plugin manager.
- The feature set is minimal, to [reduce code complexity](https://grugbrain.dev/)
  and simplify the API.
  For example, the following `lazy.nvim` features are **out of scope**:
  - Merging multiple plugin specs for a single plugin
    (primarily intended for use by Neovim distributions).
  - `lazy.vim` completely disables and takes over Neovim's
    built-in loading mechanisms, including
    adding a plugin's API (`lua`, `autoload`, ...)
    to the runtimepath.
    `lze` doesn't.
    Its only concern is plugin initialization, which is
    the bulk of the startup overhead.
  - Automatic lazy-loading of colorschemes.
    `lze` provides a `colorscheme` handler in the plugin spec.
  - Heuristics for determining a `main` module and automatically calling
    a `setup()` function.
  - Abstractions for plugin configuration with an `opts` table.
    `lze` provides simple hooks that you can use to specify
    when to load configurations.
  - Heuristics for automatically loading plugins on `require`.
    You can lazy-load on require with some configuration however!
  - Features related to plugin management.
  - Profiling tools.
  - UI.
- Some configuration options are different.

## :pencil: Requirements

- `Neovim >= 0.7.0`

## :books: Usage

```lua
require("lze").load(plugins)
```

- **plugins**: this should be a `table` or a `string`
  - `table`:
    - A list with your [Plugin Specs](#plugin-spec)
    - Or a single plugin spec.
  - `string`: a Lua module name that contains your [Plugin Spec](#plugin-spec).
    See [Structuring Your Plugins](#structuring-your-plugins)

> [!TIP]
> You can call require('lze').load() as many times as you wish.
>
> - See also: [`:h lze`](./doc/lze.txt)

> [!IMPORTANT]
>
> Since merging configs is out of scope, calling `load()` with conflicting
> plugin specs is not supported. It will prevent you from doing so,
> and return the list of duplicate names

### Examples

```lua
require("lze").load {
    {
        "neo-tree.nvim",
        keys = {
            -- Create a key mapping and lazy-load when it is used
            { "<leader>ft", "<CMD>Neotree toggle<CR>", desc = "NeoTree toggle" },
        },
        after = function()
            require("neo-tree").setup()
        end,
    },
    {
        "crates.nvim",
        -- lazy-load when opening a toml file
        ft = "toml",
    },
    {
        "sweetie.nvim",
        -- lazy-load when setting the `sweetie` colorscheme
        colorscheme = "sweetie",
    },
    {
        "vim-startuptime",
        cmd = "StartupTime",
        before = function()
            -- Configuration for plugins that don't force you to call a `setup` function
            -- for initialization should typically go in a `before`
            --- or `beforeAll` function.
            vim.g.startuptime_tries = 10
        end,
    },
    {
        "care.nvim",
        -- load care.nvim on InsertEnter
        event = "InsertEnter",
    },
    {
        "dial.nvim",
        -- lazy-load on keys. -- Mode is `n` by default.
        keys = { "<C-a>", { "<C-x>", mode = "n" } },
    },
}
```

<!-- markdownlint-disable -->
<details>
  <summary>
    <b><a href="https://neovim.io/doc/user/pack.html#vim.pack.add()">vim.pack.add example</a></b>
  </summary>

  There are several ways to use `lze` with `vim.pack.add`. Some of them are listed here.

  ```lua
  vim.pack.add({
      "https://github.com/BirdeeHub/lze",
      "https://github.com/Wansmer/treesj",
      { src = "https://github.com/nvim-telescope/telescope.nvim" },
      { src = "https://github.com/NTBBloodBatch/sweetie.nvim", name = "sweetie" }
  }, {
    -- prevent packadd! or packadd like this to allow on_require handler to load plugin spec
    load = function() end,
    -- choose your preference for install confirmation
    confirm = true,
  })
  vim.cmd.packadd("lze")

  require("lze").load {
      {
          "telescope.nvim",
          cmd = "Telescope",
      },
      {
          "sweetie", -- note the name change above
          colorscheme = "sweetie",
      },
      {
          "treesj",
          cmd = { "TSJToggle" },
          keys = { { "<leader>Tt", ":TSJToggle<CR>", mode = { "n" }, desc = "treesj split/join" }, },
          after = function(_)
              require('treesj').setup({})
          end,
      }
  }
  ```

  OR

  ```lua
  vim.pack.add({
      "https://github.com/BirdeeHub/lze",
      { src = "https://github.com/Wansmer/treesj", data = { opt = true, } },
      { src = "https://github.com/nvim-telescope/telescope.nvim", data = { opt = true, } },
      { src = "https://github.com/NTBBloodBatch/sweetie.nvim", name = "sweetie", data = { opt = true, } }
  }, {
    load = function(p)
      if not (p.spec.data or {}).opt then
        vim.cmd.packadd(p.spec.name)
      end
    end,
    -- choose your preference for install confirmation
    confirm = true,
  })

  require("lze").load {
      {
          "telescope.nvim",
          cmd = "Telescope",
      },
      {
          "sweetie", -- note the name change above
          colorscheme = "sweetie",
      },
      {
          "treesj",
          cmd = { "TSJToggle" },
          keys = { { "<leader>Tt", ":TSJToggle<CR>", mode = { "n" }, desc = "treesj split/join" }, },
          after = function(_)
              require('treesj').setup({})
          end,
      }
  }
  ```

  OR

  ```lua
  vim.pack.add({ "https://github.com/BirdeeHub/lze", }, { confirm = false --[[or true, up to you]], })
  vim.pack.add({
      {
        src = "https://github.com/Wansmer/treesj",
        data = {
          cmd = "Telescope",
        }
      }
      {
        src = "https://github.com/nvim-telescope/telescope.nvim",
        data = {
          colorscheme = "sweetie",
        }
      },
      {
        src = "https://github.com/NTBBloodBatch/sweetie.nvim",
        data = {
          cmd = { "TSJToggle" },
          keys = { { "<leader>Tt", ":TSJToggle<CR>", mode = { "n" }, desc = "treesj split/join" }, },
          after = function(_)
              require('treesj').setup({})
          end,
        }
      }
  }, {
    load = function(p)
      local spec = p.spec.data or {}
      spec.name = p.spec.name
      require('lze').load(spec)
    end,
    -- choose your preference for install confirmation
    confirm = true,
  })
```

</details>

<details>
  <summary>
    <b><a href="https://github.com/savq/paq-nvim">paq-nvim example</a></b>
  </summary>

  ```lua
  require "paq" {
      "BirdeeHub/lze",
      { "nvim-telescope/telescope.nvim", opt = true },
      { "NTBBloodBatch/sweetie.nvim", opt = true }
  }

  require("lze").load {
      {
          "telescope.nvim",
          cmd = "Telescope",
      },
      {
          "sweetie.nvim",
          colorscheme = "sweetie",
      },
  }
  ```

</details>

<details>
  <summary>
    <b><a href="https://wiki.nixos.org/wiki/Neovim">Nix examples</a></b>
  </summary>

  - Home Manager:

  ```nix
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins [
      {
        plugin = lze;
        # config = ''
        #   -- optional, add extra handlers
        #   -- require("lze").register_handlers(some_custom_handler_here)
        # '';
        # type = "lua";
      }
      {
        plugin = telescope-nvim;
        config = ''
          require("lze").load {
            "telescope.nvim",
            cmd = "Telescope",
          }
        '';
        type = "lua";
        optional = true;
      }
      {
        plugin = sweetie-nvim;
        config = ''
          require("lze").load {
            "sweetie.nvim",
            colorscheme = "sweetie",
          }
        '';
        type = "lua";
        optional = true;
      }
    ];
  };
  ```

  - [nixCats](https://github.com/BirdeeHub/nixCats-nvim)

  While the home manager syntax is also accepted by `nixCats` anywhere we can add plugins,
  `nixCats` allows you to configure it in your normal lua files.

  Add it to your `startupPlugins` set as shown below,
  put the desired plugins in `optionalPlugins` so they don't auto-load,
  then configure as in [the regular examples](#examples)
  wherever you want in your config.

  ```nix
  # in your categoryDefinitions
  categoryDefinitions = { pkgs, settings, categories, name, ... }: {
  # :help nixCats.flake.outputs.categories
    startupPlugins = with pkgs.vimPlugins; {
      someName = [
        # in startupPlugins so that it is available
        lze
      ];
    };
    optionalPlugins = with pkgs.vimPlugins; {
      someName = [
        # the plugins you wish to load via lze
      ];
      # you can name the categories whatever you want,
      # the important thing is,
      # optionalPlugins is for lazy loading via packadd
    };
  };
  # see :help nixCats.flake.outputs.packageDefinitions
  packageDefinitions = {
    nvim = {pkgs , ... }: {
      # see :help nixCats.flake.outputs.settings
      settings = {/* your settings */ };
      categories = {
        # don't forget to enable it for the desired package!
        someName = true;
        # ... your other categories here
      };
    };
  };
  # ... the rest of your nix where you call the builder and export packages
  ```

  - Not on nixpkgs-unstable?

  If your neovim is not on the `nixpkgs-unstable` channel,
  `vimPlugins.lze` may not yet be in nixpkgs for you.
  You may instead get it from this flake!
  ```nix
  # in your flake inputs:
  inputs = {
    lze.url = "github:BirdeeHub/lze";
  };
  ```
  Then, pass your config your inputs from your flake,
  and retrieve `lze` with:
  ```nix
  inputs.lze.packages.${pkgs.system}.default`:
  ```

</details>
<!-- markdownlint-restore -->

### :wrench: Configuration

You can override the function used to load plugins.
`lze` has the following defaults:

```lua
vim.g.lze = {
    injects = {},
    ---@type fun(name: string)
    load = vim.cmd.packadd,
    ---@type boolean
    verbose = true,
    ---@type integer
    default_priority = 50,
    ---@type boolean
    without_default_handlers = false,
}
```

`vim.g.lze.without_default_handlers` must be set before you require `lze`
or it will have no effect.

If `vim.g.lze.verbose` is `false` it will not print a warning
in cases of duplicate and missing plugins, or when passing in an empty list.

`vim.g.lze.load` defines the fallback function used for the load hook for plugins.
This value is not present in the plugin spec when handlers receive the plugin spec.

In contrast, `vim.g.lze.injects` injects default values
for ANY field BEFORE any handlers receive the plugin spec.

### Plugin spec

#### Loading hooks

<!-- markdownlint-disable MD013 -->
| Property         | Type | Description | `lazy.nvim` equivalent |
|------------------|------|-------------|-----------------------|
| **[1]** | `string` | REQUIRED. The plugin's name (not the module name, and not the url). This is the directory name of the plugin in the packpath and is usually the same as the repo name of the repo it was cloned from. | `name`[^1] |
| **enabled?** | `boolean` or `fun():boolean` | When `false`, or if the `function` returns `nil` or `false`, then this plugin will not be included in the spec. | `enabled` |
| **beforeAll?** | `fun(lze.Plugin)` | Always executed upon calling `require('lze').load(spec)` before any plugin specs from that call are triggered to be loaded. | `init` |
| **before?** | `fun(lze.Plugin)` | Executed before a plugin is loaded. | None |
| **after?** | `fun(lze.Plugin)` | Executed after a plugin is loaded. | `config` |
| **priority?** | `number` | Only useful for **start** plugins (not lazy-loaded) added within **the same `require('lze').load(spec)` call** to force loading certain plugins first. Default priority is `50`, or the value of `vim.g.lze.default_priority`. | `priority` |
| **load?** | `fun(string)` | Can be used to override the `vim.g.lze.load(name)` function for an individual plugin. (default is `vim.cmd.packadd(name)`)[^2] | None. |
| **allow_again?** | `boolean` or `fun():boolean` | When a plugin has ALREADY BEEN LOADED, true would allow you to add it again. No idea why you would want this outside of testing. | None. |
| **lazy?** | `boolean` | Using a handler's field sets this automatically, but you can set this manually as well. | `lazy` |
<!-- markdownlint-enable MD013 -->

#### Lazy-loading triggers provided by the default handlers

<!-- markdownlint-disable MD013 -->
| Property | Type | Description | `lazy.nvim` equivalent |
|----------|------|-------------|----------------------|
| **event?** | `string` or `{event?:string\|string[], pattern?:string\|string[]}\` or `string[]` | Lazy-load on event. Events can be specified as `BufEnter` or with a pattern like `BufEnter *.lua`. | `event` |
| **cmd?** | `string` or `string[]` | Lazy-load on command. | `cmd` |
| **ft?** | `string` or `string[]` | Lazy-load on filetype. | `ft` |
| **keys?** | `string` or `string[]` or `lze.KeysSpec[]` | Lazy-load on key mapping. | `keys` |
| **colorscheme?** | `string` or `string[]` | Lazy-load on colorscheme. | None. `lazy.nvim` lazy-loads colorschemes automatically[^3]. |
| **dep_of?** | `string` or `string[]` | Lazy-load before another plugin but after its `before` hook. Accepts a plugin name or a list of plugin names. |  None but is sorta the reverse of the dependencies key of the `lazy.nvim` plugin spec |
| **on_plugin?** | `string` or `string[]` | Lazy-load after another plugin but before its `after` hook. Accepts a plugin name or a list of plugin names. | None. |
| **on_require?** | `string` or `string[]` | Accepts a top-level **lua module** name or a list of top-level **lua module** names. Will load when any submodule of those listed is `require`d | None. `lazy.nvim` does this automatically. |
<!-- markdownlint-enable MD013 -->

[^1]: In contrast to `lazy.nvim`'s `name` field, a `lze.PluginSpec`'s `name` *is not optional*.
      This is because `lze` is not a plugin manager and needs to be told which
      plugins to load.
[^2]: for example, lazy-loading cmp sources will
      require you to source its `after/plugin` file,
      as packadd does not do this automatically for you.
[^3]: The reason this library doesn't lazy-load colorschemes automatically is that
      it would have to know where the plugin is installed in order to determine
      which plugin to load.

### User events

- `DeferredUIEnter`: Triggered when `require('lze').load()` is done and after `UIEnter`.
  Can be used as an `event` to lazy-load plugins that are not immediately needed
  for the initial UI[^4].

But users may define more aliased events if they wish.
The event handler exports a function you may call to set them.

`require('lze').h.event.set_event_alias(name: string, spec: lze.EventSpec?)`

[^4]: This is equivalent to `lazy.nvim`'s `VeryLazy` event.

### Plugins with after directories

Relying on another plugin's `plugin` or `after/plugin` scripts is considered a bug,
as Neovim's built-in loading mechanism does not guarantee initialisation order.
Requiring users to manually call a `setup` function [is an anti pattern](https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#zap-initialization).
Forcing users to think about the order in which they load plugins that
extend or depend on each other is not great either and we
suggest opening an issue or submitting
a PR to fix any of these issues upstream.

> [!NOTE]
>
> - `vim.cmd.packadd` does not work with plugins that rely
>   on `after` directories of plugins, such as many
>   nvim-cmp sources.
>   To source `after` directories of a plugin,
>   you should replace the load function for the plugin with:

```lua
local function load_with_after(name)
    vim.cmd.packadd(name)
    vim.cmd.packadd(name .. "/after")
end
```

For example:

```lua
require("lze").load {
  "cmp-cmdline",
  on_plugin = { "nvim-cmp" },
  load = load_with_after,
}
```

[lzextras](https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#loaders)
provides this function and a few others as well!

> [!NOTE]
>
> - You may also wish to use [`rtp.nvim`](https://github.com/nvim-neorocks/rtp.nvim)
>   for sourcing `ftdetect` files in plugins without loading them,
>   for when plugins provide their own filetypes
>   and you wish to trigger on that filetype.

### Structuring Your Plugins

Unlike `lazy.nvim`, in `lze` you may call
`require('lze').load` as many times as you would like.

This means being able to import files via specs is not as useful.

The import spec of `lze` allows for importing a single lua module,
unlike `lz.n` or `lazy.nvim`, where it imports an entire directory.

That module may return a list of specs,
which means it can also return a list of import specs.

This way, you get to choose the order, and can
have files in that directory that are not imported if you wish.

```lua
require("lze").load("plugins")
```

where `lua/plugins` in your config contains an `init.lua` with something like,

<!-- markdownlint-disable -->
```lua
return {
  {
    "undotree",
    cmd = {
      "UndotreeToggle",
      "UndotreeHide",
      "UndotreeShow",
      "UndotreeFocus",
      "UndotreePersistUndo",
    },
    keys = { { "<leader>U", "<cmd>UndotreeToggle<CR>", mode = { "n" }, desc = "Undo Tree" }, },
    before = function(_)
      vim.g.undotree_WindowLayout = 1
      vim.g.undotree_SplitWidth = 40
    end,
  },
  { import = "plugins.afile" },
  { import = "plugins.another" },
  { import = "plugins.another_file" },
  { import = "plugins.yet_another_file" },
}
```
<!-- markdownlint-restore -->

where the imported files would return plugin specs as shown above.

## :electric_plug: API

### Custom handlers

You may register your own handlers to lazy-load plugins via
other triggers not already covered by the plugin spec.

```lua
---@param handlers lze.Handler[]|lze.Handler|lze.HandlerSpec[]|lze.HandlerSpec
---@return string[] handlers_registered
require("lze").register_handlers({
    require("my_handlers.module1"),
    require("my_handlers.module2"),
    {
        handler = require("my_handlers.module3"),
        enabled = true,
    },
})
```

You may call this function multiple times,
each call will append the new handlers (if enabled) to the end of the list.

The handlers define the fields you may use for lazy loading,
with the fields like `ft` and `event` that exist
in the default plugin spec being defined by
the [default handlers](./lua/lze/h).

The order of this list of handlers is important.

It is the same as the order in which their hooks are called.

If you wish to redefine a default handler, or change the order
in which the default handlers are called,
there exists a `require('lze').clear_handlers()`
and a `require('lze').remove_handlers(handler_names: string|string[])`
function for this purpose. They return the removed handlers.

> [!WARNING]
> You must register ALL handlers before calling `require('lze').load`,
> because they will not be retroactively applied to
> the `load` calls that occur before they are registered.
>
> In addition, removing a handler after it already
> has had plugins added to it is undefined behavior.
> Existing plugin items will remain in state
> and trigger-able via `require('lze').trigger_load`
>
> While the default handlers clear their state when removed,
> it is not necessary to be adding and removing handlers often
> for the purpose of loading plugins or various things in your config.
>
> So you should do ALL handler additions AND removals
> BEFORE calling `require('lze').load`.

#### lze.HandlerSpec

You can also add them as specs instead of just directly as a list.

<!-- markdownlint-disable MD013 -->
| Property   | Type                         | Description                                               |
| ---        | ---                          | ---                                                       |
| handler | `lze.Handler`                   | the `lze.Handler` you wish to add |
| enabled? | `boolean?` or `fun():boolean?` | determines at time of registration if the handler should be added or not. Defaults to `true` |
<!-- markdownlint-enable MD013 -->

### Writing Custom Handlers

#### `lze.Handler`

<!-- markdownlint-disable MD013 -->
| Property   | Type                              | Description                                               |
| ---        | ---                               | ---                                                       |
| spec_field | `string`                          | the `lze.PluginSpec` field used to configure the handler |
| add?        | `fun(plugin: lze.Plugin): fun()?`        | called once for each handler before any plugin has been loaded. Tells your handler about each plugin so you can set up a trigger for it if your handler was used. |
| before?        | `fun(name: string)`               | called after each plugin spec's before `hook`, and before its `load` hook |
| after?        | `fun(name: string)`               | called after each plugin spec's `load` hook and before its `after` hook |
| modify?     | `fun(plugin: lze.Plugin): lze.Plugin, fun()?` | This function is called before a plugin is added to state. It is your one chance to modify the plugin spec, it is active only if your spec_field was used in that spec, and is called in the order the handlers have been added. |
| set_lazy?     | `boolean` | Whether using this handler's field should have an effect on the lazy setting. True or nil is true. Default: nil |
| post_def?        | `fun()`               | For adding custom triggers such as the event handler's `DeferredUIEnter` event, called at the end of `require('lze').load` |
| lib?        | `table`               | Handlers may export functions and other values via this set, which then may be accessed via `require('lze').h[spec_field].your_func()` |
| init?        | `fun()`               | Called when the handler is registered. |
| cleanup?        | `fun()`               | Called when the handler is removed. |
<!-- markdownlint-enable MD013 -->

All handler hooks will be called in the order in which your handlers are registered.

Your handler first has a chance to modify the
parsed plugin spec before it is loaded into the state of `lze`.
None of the builtin handlers have this hook.

The `modify` field of a handler will only be called if that handler's
`spec_field` was used in that [plugin spec](#plugin-spec) (meaning, it is not nil).

It is called before the plugin is added to state,
and thus you will not be able to call `trigger_load` on it yet.
To get around this, you may return a function
as an optional second return value, which will
be called after `add` and before any functions deferred by `add`.

Then, your handler will have a chance to add plugins to its list to trigger
via its `add` hook. The `add` hook is called
before any plugins have been loaded
in that `require('lze').load` call.

You should also avoid calling `trigger_load` in the `add` hook,
as it may not have been added to all handlers yet.
You may optionally return a function in order to defer code
until after all `add` hooks and all functions
deferred by `modify` have been called.

Your handler will then decide when to load
a plugin and run its associated hooks
using the `trigger_load` function.

```lua
---@overload fun(plugin_name: string | string[]): string[]
require('lze').trigger_load
```

`trigger_load` will resist being called multiple times on the same plugin name.
It will return the list of names it skipped.

There exists a function to check if a plugin is available to be loaded.

`require('lze').state(name)` will return true
if the plugin is ready to be loaded,
false if already loaded or currently being loaded,
and nil if it was never added.

Less performant, but more informative:

For debugging purposes, or if necessary,
you may use the table access form `require('lze').state[name]`
which will return a COPY of the internal state of the plugin.

You should already have a copy of the plugin
via your handler's add function so you shouldn't
ever NEED to get a copy. But it is nice for troubleshooting.

> [!TIP]
> You should delete the plugin from your handler's state
> in either the `before` or `after` hooks
> so that you don't have to carry around
> unnecessary state and increase your chance of error and your memory usage.
> However, not doing so would not cause any bugs in `lze`.
> It just might let you call `trigger_load` multiple times to no effect.

## :green_heart: Contributing

All contributions are welcome!
See [CONTRIBUTING.md](./CONTRIBUTING.md).

## :book: License

This library is [licensed](./LICENSE) according to GPL version 2
or (at your option) any later version.

<!-- MARKDOWN LINKS & IMAGES -->
<!-- markdownlint-disable MD013 -->
[neovim-shield]: https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[luarocks-shield]:
https://img.shields.io/luarocks/v/BirdeeHub/lze?logo=lua&color=purple&style=for-the-badge
[luarocks-url]: https://luarocks.org/modules/BirdeeHub/lze
<!-- markdownlint-enable MD013 -->
