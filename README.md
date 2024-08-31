<!-- markdownlint-disable MD028 -->
# :sloth: lze

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![LuaRocks][luarocks-shield]][luarocks-url]

A dead simple lazy-loading Lua library for Neovim plugins.

It is intended to be used

- by users of plugin managers that don't provide a convenient API for lazy-loading.
- by plugin managers, to provide a convenient API for lazy-loading.

## :question: Is this [lz.n](https://github.com/nvim-neorocks/lz.n)?

Nope. I quite like `lz.n`. I have contributed to `lz.n` many times.

In fact, I have contributed to `lz.n` after this plugin has been created.

I have also written 2 custom handlers for it,
both of which are on its wiki.

`lz.n` is a great plugin. This is my take on `lz.n`

The core has been entirely rewritten
and it handles its state entirely differently. [^1]

It shares some code where handlers parse their specs,
otherwise it works entirely differently, but
with a largely compatible [plugin spec](#plugin-spec)

It has almost the same exact plugin spec, with 2 extra fields.

However, import specs can only import a
single module rather than a whole directory.

Why?

`lze` actually treats your list of specs as a list.
If your startup plugins have not been given a priority,
they load in the order passed in.

What order should the directory be imported in? I left it up to you.

Handlers are very different. They have much less
responsibility to manage state for lze.

Handlers can achieve all the same things,
but in a different way. Possibly more, but I am not sure.

Which one is better? Hard to say.

Neither is appreciably faster than the other.

The plugin specs are basically the same.

Its basically down to which design of handlers you prefer.

<!-- markdownlint-disable MD013 -->
It also has a built-in dep_of handler, rather than you needing to add
a third party one such as the one I posted to `lz.n` [wiki](https://github.com/nvim-neorocks/lz.n/wiki/Custom-handler-examples#dependency-handler),
as well as an on_plugin handler that loads after load of another plugin.
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-disable MD007 MD032 -->
[^1]: `lze`'s state is actually authoritative, due to
    `trigger_load` not accepting a plugin spec like its `lz.n` equivalent does,
    and the core state is NOT editable outside of a handler's modify hook.
<!-- markdownlint-enable MD007 MD032 -->

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
> Regardless, the current status quo is horrible, and some authors may
> not have the will or capacity to improve their plugins' startup impact.
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

- `Neovim >= 0.10.0`

## :wrench: Configuration

You can override the function used to load plugins.
`lze` has the following defaults:

```lua
vim.g.lze = {
    ---@type fun(name: string)
    load = vim.cmd.packadd,
    ---@type boolean
    verbose = true,
}
```

If `vim.g.lze.verbose` is `false` it will not print a warning
in cases of duplicate and missing plugins.

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

### Plugin spec

#### Loading hooks

<!-- markdownlint-disable MD013 -->
| Property         | Type | Description | `lazy.nvim` equivalent |
|------------------|------|-------------|-----------------------|
| **[1]** | `string` | REQUIRED. The plugin's name (not the module name). This is the directory name of the plugin in the packpath and is usually the same as the repo name of the repo it was cloned from. | `name`[^2] |
| **enabled?** | `boolean` or `fun():boolean` | When `false`, or if the `function` returns false, then this plugin will not be included in the spec. | `enabled` |
| **beforeAll?** | `fun(lze.Plugin)` | Always executed upon calling `require('lze').load(spec)` before any plugin specs from that call are triggered to be loaded. | `init` |
| **before?** | `fun(lze.Plugin)` | Executed before a plugin is loaded. | None |
| **after?** | `fun(lze.Plugin)` | Executed after a plugin is loaded. | `config` |
| **priority?** | `number` | Only useful for **start** plugins (not lazy-loaded) added within **the same `require('lze').load(spec)` call** to force loading certain plugins first. Default priority is `50`. | `priority` |
| **load?** | `fun(string)` | Can be used to override the `vim.g.lze.load(name)` function for an individual plugin. (default is `vim.cmd.packadd(name)`)[^3] | None. |
| **allow_again?** | `boolean` or `fun():boolean` | When a plugin has ALREADY BEEN LOADED, true would allow you to add it again. No idea why you would want this outside of testing. | None. |
<!-- markdownlint-enable MD013 -->

#### Lazy-loading triggers provided by the default handlers

<!-- markdownlint-disable MD013 -->
| Property | Type | Description | `lazy.nvim` equivalent |
|----------|------|-------------|----------------------|
| **event?** | `string` or `{event?:string\|string[], pattern?:string\|string[]}\` or `string[]` | Lazy-load on event. Events can be specified as `BufEnter` or with a pattern like `BufEnter *.lua`. | `event` |
| **cmd?** | `string` or `string[]` | Lazy-load on command. | `cmd` |
| **ft?** | `string` or `string[]` | Lazy-load on filetype. | `ft` |
| **keys?** | `string` or `string[]` or `lze.KeysSpec[]` | Lazy-load on key mapping. | `keys` |
| **colorscheme?** | `string` or `string[]` | Lazy-load on colorscheme. | None. `lazy.nvim` lazy-loads colorschemes automatically[^4]. |
| **dep_of?** | `string` or `string[]` | Lazy-load before another plugin but after its `before` hook. Accepts a plugin name or a list of plugin names. |  None but is sorta the reverse of the dependencies key of the `lazy.nvim` plugin spec |
| **on_plugin?** | `string` or `string[]` | Lazy-load after another plugin but before its `after` hook. Accepts a plugin name or a list of plugin names. | None. |
<!-- markdownlint-enable MD013 -->

[^2]: In contrast to `lazy.nvim`'s `name` field, a `lze.PluginSpec`'s `name` *is not optional*.
      This is because `lze` is not a plugin manager and needs to be told which
      plugins to load.
[^3]: for example, lazy-loading cmp sources will
      require you to source its `after/plugin` file,
      as packadd does not do this automatically for you.
[^4]: The reason this library doesn't lazy-load colorschemes automatically is that
      it would have to know where the plugin is installed in order to determine
      which plugin to load.

### User events

- `DeferredUIEnter`: Triggered when `require('lze').load()` is done and after `UIEnter`.
  Can be used as an `event` to lazy-load plugins that are not immediately needed
  for the initial UI[^5].

[^5]: This is equivalent to `lazy.nvim`'s `VeryLazy` event.

### Plugins with after directories

Relying on another plugin's `plugin` or `after/plugin` scripts is considered a bug,
as Neovim's built-in loading mechanism does not guarantee initialisation order.
Requiring users to manually call a `setup` function [is an anti pattern](https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#zap-initialization).
Forcing users to think about the order in which they load plugins that
extend or depend on each other is even worse. We strongly suggest opening
an issue or submitting a PR to fix this upstream.
However, if you're looking for a temporary workaround, you can use
`trigger_load` in a `before` or `after` hook, or bundle the relevant plugin configurations.

> [!NOTE]
>
> - This does not work with plugins that rely on `after/plugin`, such as many
>   nvim-cmp sources, because Neovim's `:h packadd` does not source
>   `after/plugin` scripts after startup has completed.
>   We recommend bundling such plugins with their extensions, or sourcing
>   the `after` scripts manually.
>   In the spirit of the UNIX philosophy, `lze` does not provide any functions
>   for sourcing plugin scripts. For sourcing `after/plugin` directories
>   manually, you can use [`rtp.nvim`](https://github.com/nvim-neorocks/rtp.nvim).
>   [Here is an example](https://github.com/nvim-neorocks/lz.n/wiki/lazy%E2%80%90loading-nvim%E2%80%90cmp-and-its-extensions).

> [!TIP]
>
> We recommend [care.nvim](https://max397574.github.io/care.nvim/)
> as a modern alternative to nvim-cmp.

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
    <b><a href="https://github.com/savq/paq-nvim">paq-nvim</a> example</b>
  </summary>

  ```lua
  require "paq" {
      { "nvim-telescope/telescope.nvim", opt = true }
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

  ```nix
  # in your flake inputs:
  inputs.lze.url = "github:BirdeeHub/lze";

  # when it makes it onto nixpkgs, it will eventually
  # be available as pkgs.vimPlugins.lze
  # without needing this part
```
Then, pass your home manager module your inputs,
and retrieve lze with `inputs.lze.packages.${pkgs.system}.default`:

  ```nix
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins [
      inputs.lze.packages.${pkgs.system}.default
      {
        plugin = pkgs.vimPlugins.telescope-nvim;
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
        plugin = pkgs.vimPlugins.sweetie-nvim;
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

  While the home manager syntax is also accepted by nixCats anywhere we can add plugins,
  nixCats allows you to configure it in your normal lua files.

  Add it to your startupPlugins set as shown below,
  put the desired plugins in optionalPlugins so they dont auto-load,
  then configure as in [the regular examples](#examples)
  wherever you want in your config.

  ```nix
  # in your categoryDefinitions
  categoryDefinitions = { pkgs, settings, categories, name, ... }: {
  # :help nixCats.flake.outputs.categories
    startupPlugins = {
      someName = [
        # in startupPlugins so that it is available
        inputs.lze.packages.${pkgs.system}.default
      ];
    };
    optionalPlugins = {
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

</details>
<!-- markdownlint-restore -->

### Structuring Your Plugins

The import spec of lze allows for importing a single lua module,
unlike `lz.n` or `lazy.nvim`, where it imports an entire directory.

That module may return a list of specs,
which means it can also return a list of import specs.

This way, you get to choose the order, and can
have files in that directory that are not imported if you wish.

```lua
require("lze").load("plugins")
```

where lua/plugins in your config contains an init.lua with something like,

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

> [!WARNING]
> You must register ALL handlers before calling `require('lze').load`,
> because they will not be retroactively applied to
> the `load` calls that occur before they are registered.

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
in the default plugin spec being defined by the [default handlers](./lua/lze/h).

The order of this list of handlers is important.

It is the same as the order in which their hooks are called.

If you wish to redefine a default handler, or change the order
in which the default handlers are called,
there exists a `require('lze').clear_handlers()`
function for this purpose. It returns the removed handlers.

Here is an example of how you would add a custom handler
BEFORE the default list of handlers:

<!-- markdownlint-disable MD013 -->
```lua
local default_handlers = require('lze').clear_handlers() -- clear_handlers removes ALL handlers
-- and now we can register them in any order we want.
require("lze").register_handlers(require("my_handlers.b4_defaults"))
require("lze").register_handlers(default_handlers)
```
<!-- markdownlint-enable MD013 -->

Again, this is important:

> [!WARNING]
> You must register ALL handlers before calling `require('lze').load`,
> because they will not be retroactively applied to
> the `load` calls that occur before they are registered.

#### `lze.Handler`

<!-- markdownlint-disable MD013 -->
| Property   | Type                              | Description                                               |
| ---        | ---                               | ---                                                       |
| spec_field | `string`                          | the `lze.PluginSpec` field used to configure the handler |
| add        | `fun(plugin: lze.Plugin)`        | called once for each handler before any plugin has been loaded. Tells your handler about each plugin so you can set up a trigger for it if you handler was used. |
| before?        | `fun(name: string)`               | called after each plugin spec's before `hook`, and before its `load` hook |
| after?        | `fun(name: string)`               | called after each plugin spec's `load` hook and before its `after` hook |
| modify?     | `fun(name: string): lze.Plugin` | This function is called before a plugin is added to state. It is your one chance to modify the plugin spec, it is active only if your spec_field was used in that spec, and is called in the order the handlers have been added. |
| post_def?        | `fun()`               | For adding custom triggers such as the event handler's `DeferredUIEnter` event, called at the end of `require('lze').load` |
<!-- markdownlint-enable MD013 -->

#### Writing Custom Handlers

Your handler first has a chance to modify the
parsed plugin spec before it is loaded into the state of `lze`.

The modify field of a handler will only be called if that handler's
`spec_field` was used in that [plugin spec](#plugin-spec).

They will be called in the order in which your handlers are registered,
and none of the builtin handlers use it.

Then, your handler will have a chance to add plugins to its list to trigger,
via its `add` function, which is called before any plugins have been loaded
in that `require('lze').load` call.

You can manually load a plugin and run its associated hooks
using the `trigger_load` function.

```lua
  ---@overload fun(plugin_name: string | string[]): string[]
  require('lze').trigger_load
```

`trigger_load` will resist being called multiple times on the same plugin name.
It will return the list of names it skipped.

For debugging purposes, or if necessary, you may use `require('lze').query_state(name)`
which will return a copy of the state of the plugin, false if loaded or being loaded,
and nil if it was never added.

> [!TIP]
> You should delete the plugin from your handler's state
> in either the `before` or `after` hooks
> so that you dont have to carry around
> unnecessary state and increase your chance of error and your memory usage.
> However, not doing so would not cause any bugs in lze.
> It just might let you call trigger_load multiple times unnecessarily

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
