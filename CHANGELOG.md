# Changelog

## [1.8.4](https://github.com/BirdeeHub/lze/compare/v1.8.3...v1.8.4) (2024-08-26)


### Bug Fixes

* **handlers:** dep_of and on_plugin, same case, different problem ([e65abcd](https://github.com/BirdeeHub/lze/commit/e65abcdc3bea45800e49e426fcc7359009f74f7e))

## [1.8.3](https://github.com/BirdeeHub/lze/compare/v1.8.2...v1.8.3) (2024-08-26)


### Bug Fixes

* **handlers:** dep_of and on_plugin, in case of target already loaded ([42ca3bd](https://github.com/BirdeeHub/lze/commit/42ca3bd86b1c553e7d1b994638ad723eb0c43129))

## [1.8.0](https://github.com/BirdeeHub/lze/compare/v1.7.0...v1.8.0) (2024-08-23)


### Features

* **in-editor docs:** added a lemmy pre-commit hook ([f654a01](https://github.com/BirdeeHub/lze/commit/f654a017b7488656c334e072a60c96df20315293))

## [1.7.0](https://github.com/BirdeeHub/lze/compare/v1.6.5...v1.7.0) (2024-08-23)


### Features

* **lze.load list handling improvements:** adds ALL non-duplicates ([2282727](https://github.com/BirdeeHub/lze/commit/2282727e35ea46289fd605454d00ca5f55e9c8fd))

## [1.6.5](https://github.com/BirdeeHub/lze/compare/v1.6.4...v1.6.5) (2024-08-23)


### Bug Fixes

* **trigger_load error message:** error message could be incorrect ([5a60d03](https://github.com/BirdeeHub/lze/commit/5a60d0380e91b10037f96efdb114cfd6d2b141ef))

## [1.6.3](https://github.com/BirdeeHub/lze/compare/v1.6.1...v1.6.3) (2024-08-23)


### Features

* **make_load_with_after:** util for sourcing after directories ([68769ca](https://github.com/BirdeeHub/lze/commit/68769ca28a0264e1f8486af7b75506c51c82b95b))

## [1.6.1](https://github.com/BirdeeHub/lze/compare/v1.6.0...v1.6.1) (2024-08-22)


### Bug Fixes

* **colorscheme handler:** There was no reason for it to set priority ([a85d11d](https://github.com/BirdeeHub/lze/commit/a85d11db1167ea8936a299382fdd4004e9412ba8))

## [1.6.0](https://github.com/BirdeeHub/lze/compare/v1.5.0...v1.6.0) (2024-08-22)


### Features

* **trigger_load:** now treats the list as a list as expected ([b9b24e9](https://github.com/BirdeeHub/lze/commit/b9b24e97969845d81a2edc77a669ef4e578cf457))

## 1.0.0 (2024-08-20)


### ⚠ BREAKING CHANGES

* simplify state management + idempotent `trigger_load` ([#56](https://github.com/BirdeeHub/lze/issues/56))

### Features

* add `before` hook ([19beffc](https://github.com/BirdeeHub/lze/commit/19beffc4d943aa29fe1edb459833f008d107b9d8))
* add `DeferredUIEnter` user event ([0a3b2c5](https://github.com/BirdeeHub/lze/commit/0a3b2c5e12ced350aec9b6dd797b824e7e34e76a))
* add `PluginSpec.config` ([b52a46c](https://github.com/BirdeeHub/lze/commit/b52a46c624fee24e4ba91a5a29be45c70e45ce5a))
* automatically increase `priority` if `colorscheme` is set ([655ab06](https://github.com/BirdeeHub/lze/commit/655ab06f4686371f07717c915b16eb4b18f6ef31))
* extend lz.n with custom handlers ([#17](https://github.com/BirdeeHub/lze/issues/17)) ([d61186f](https://github.com/BirdeeHub/lze/commit/d61186fc231797e07986e4dc59f789d8660dc822))
* forked from lz.n, see readme for changes ([8de2797](https://github.com/BirdeeHub/lze/commit/8de279719d36ba1f64ea691b9312a7f5b9125eb4))
* handler for lazy-loading colorschemes ([d4a2eeb](https://github.com/BirdeeHub/lze/commit/d4a2eebb84b1c000a8388e167be3cb8f9d1edfe4))
* register individual plugin specs for lazy loading ([b9c03c1](https://github.com/BirdeeHub/lze/commit/b9c03c1ed2fd95abd657a7310310aeee039cd3ec))
* simplify state management + idempotent `trigger_load` ([#56](https://github.com/BirdeeHub/lze/issues/56)) ([701d6ac](https://github.com/BirdeeHub/lze/commit/701d6acc030d1ed6ef16b7efe4d752dbf7d7f13b))
* support importing `init.lua` submodules ([5c3c2a1](https://github.com/BirdeeHub/lze/commit/5c3c2a1eb4df0260f9ed738ec321aa85ecf8e0f9))
* support loading plugin spec lists and imports more than once ([d911029](https://github.com/BirdeeHub/lze/commit/d9110299475823eff784a6ccf6aa3f63dea9b295))


### Bug Fixes

* actually support importing plugin specs from files ([5553dc5](https://github.com/BirdeeHub/lze/commit/5553dc52fa696f1e8162329a91e9055ff71020d6))
* altered loading order for startup plugins ([#49](https://github.com/BirdeeHub/lze/issues/49)) ([50c1454](https://github.com/BirdeeHub/lze/commit/50c145466330c0c5b272fd3904b5655a1613149c))
* colorscheme handler broken for `start` plugins ([#41](https://github.com/BirdeeHub/lze/issues/41)) ([7ba8692](https://github.com/BirdeeHub/lze/commit/7ba8692a5f88c04de5791232887823e0f40f9525))
* colorscheme lists inserted into wrong table ([9fe735e](https://github.com/BirdeeHub/lze/commit/9fe735e6ca5e835f953ab284188cd31322804e43))
* ensure individual plugins can only be registered once ([47a10af](https://github.com/BirdeeHub/lze/commit/47a10afe2c4eae2d5429864acaba536073f6e089))
* **event:** broken `DeferredUIEnter` event ([cf11ec2](https://github.com/BirdeeHub/lze/commit/cf11ec2b1696dddd5620a055244cc0860f982677))
* **keys:** don't ignore modes that aren't `'n'` ([#28](https://github.com/BirdeeHub/lze/issues/28)) ([8886765](https://github.com/BirdeeHub/lze/commit/8886765a2fcc9b9550dbd2e8d9bb5535f1de290d))
* odd intermittent issue with load function ([#21](https://github.com/BirdeeHub/lze/issues/21)) ([1ac92ff](https://github.com/BirdeeHub/lze/commit/1ac92fff5da1212174956b20383a75b6268c56a7))
* spdx license identifier in release rockspec ([5c71d03](https://github.com/BirdeeHub/lze/commit/5c71d03bfad28298b1a9cf11f7ce134b5ad6318a))
* spec list with a single plugin spec ignored ([#34](https://github.com/BirdeeHub/lze/issues/34)) ([e0831fe](https://github.com/BirdeeHub/lze/commit/e0831fee3109a56705a6eea896e1d7d5d157a04d))
* support /nix/store links ([fa625dd](https://github.com/BirdeeHub/lze/commit/fa625dd86414dc830c6c9b7188fe4cd583e664c4))

## [1.4.4](https://github.com/nvim-neorocks/lz.n/compare/v1.4.3...v1.4.4) (2024-08-09)


### Bug Fixes

* colorscheme handler broken for `start` plugins ([#41](https://github.com/nvim-neorocks/lz.n/issues/41)) ([7ba8692](https://github.com/nvim-neorocks/lz.n/commit/7ba8692a5f88c04de5791232887823e0f40f9525))

## [1.4.3](https://github.com/nvim-neorocks/lz.n/compare/v1.4.2...v1.4.3) (2024-07-10)


### Bug Fixes

* spec list with a single plugin spec ignored ([#34](https://github.com/nvim-neorocks/lz.n/issues/34)) ([e0831fe](https://github.com/nvim-neorocks/lz.n/commit/e0831fee3109a56705a6eea896e1d7d5d157a04d))

## [1.4.2](https://github.com/nvim-neorocks/lz.n/compare/v1.4.1...v1.4.2) (2024-06-29)


### Bug Fixes

* **keys:** don't ignore modes that aren't `'n'` ([#28](https://github.com/nvim-neorocks/lz.n/issues/28)) ([8886765](https://github.com/nvim-neorocks/lz.n/commit/8886765a2fcc9b9550dbd2e8d9bb5535f1de290d))

## [1.4.1](https://github.com/nvim-neorocks/lz.n/compare/v1.4.0...v1.4.1) (2024-06-26)


### Bug Fixes

* odd intermittent issue with load function ([#21](https://github.com/nvim-neorocks/lz.n/issues/21)) ([1ac92ff](https://github.com/nvim-neorocks/lz.n/commit/1ac92fff5da1212174956b20383a75b6268c56a7))

## [1.4.0](https://github.com/nvim-neorocks/lz.n/compare/v1.3.2...v1.4.0) (2024-06-24)


### Features

* extend lz.n with custom handlers ([#17](https://github.com/nvim-neorocks/lz.n/issues/17)) ([d61186f](https://github.com/nvim-neorocks/lz.n/commit/d61186fc231797e07986e4dc59f789d8660dc822))

## [1.3.2](https://github.com/nvim-neorocks/lz.n/compare/v1.3.1...v1.3.2) (2024-06-19)


### Bug Fixes

* **event:** broken `DeferredUIEnter` event ([cf11ec2](https://github.com/nvim-neorocks/lz.n/commit/cf11ec2b1696dddd5620a055244cc0860f982677))

## [1.3.1](https://github.com/nvim-neorocks/lz.n/compare/v1.3.0...v1.3.1) (2024-06-19)


### Bug Fixes

* support /nix/store links ([fa625dd](https://github.com/nvim-neorocks/lz.n/commit/fa625dd86414dc830c6c9b7188fe4cd583e664c4))

## [1.3.0](https://github.com/nvim-neorocks/lz.n/compare/v1.2.4...v1.3.0) (2024-06-18)


### Features

* support importing `init.lua` submodules ([5c3c2a1](https://github.com/nvim-neorocks/lz.n/commit/5c3c2a1eb4df0260f9ed738ec321aa85ecf8e0f9))
* support loading plugin spec lists and imports more than once ([d911029](https://github.com/nvim-neorocks/lz.n/commit/d9110299475823eff784a6ccf6aa3f63dea9b295))

## [1.2.4](https://github.com/nvim-neorocks/lz.n/compare/v1.2.3...v1.2.4) (2024-06-17)


### Bug Fixes

* actually support importing plugin specs from files ([5553dc5](https://github.com/nvim-neorocks/lz.n/commit/5553dc52fa696f1e8162329a91e9055ff71020d6))

## [1.2.3](https://github.com/nvim-neorocks/lz.n/compare/v1.2.2...v1.2.3) (2024-06-16)


### Bug Fixes

* colorscheme lists inserted into wrong table ([9fe735e](https://github.com/nvim-neorocks/lz.n/commit/9fe735e6ca5e835f953ab284188cd31322804e43))

## [1.2.2](https://github.com/nvim-neorocks/lz.n/compare/v1.2.1...v1.2.2) (2024-06-16)


### Bug Fixes

* spdx license identifier in release rockspec ([5c71d03](https://github.com/nvim-neorocks/lz.n/commit/5c71d03bfad28298b1a9cf11f7ce134b5ad6318a))

## [1.2.1](https://github.com/nvim-neorocks/lz.n/compare/v1.2.0...v1.2.1) (2024-06-16)


### Bug Fixes

* ensure individual plugins can only be registered once ([47a10af](https://github.com/nvim-neorocks/lz.n/commit/47a10afe2c4eae2d5429864acaba536073f6e089))

## [1.2.0](https://github.com/nvim-neorocks/lz.n/compare/v1.1.0...v1.2.0) (2024-06-16)


### Features

* register individual plugin specs for lazy loading ([b9c03c1](https://github.com/nvim-neorocks/lz.n/commit/b9c03c1ed2fd95abd657a7310310aeee039cd3ec))

## [1.1.0](https://github.com/nvim-neorocks/lz.n/compare/v1.0.0...v1.1.0) (2024-06-15)


### Features

* add `DeferredUIEnter` user event ([0a3b2c5](https://github.com/nvim-neorocks/lz.n/commit/0a3b2c5e12ced350aec9b6dd797b824e7e34e76a))

## 1.0.0 (2024-06-10)


### Features

* add `before` hook ([19beffc](https://github.com/nvim-neorocks/lz.n/commit/19beffc4d943aa29fe1edb459833f008d107b9d8))
* add `PluginSpec.config` ([b52a46c](https://github.com/nvim-neorocks/lz.n/commit/b52a46c624fee24e4ba91a5a29be45c70e45ce5a))
* automatically increase `priority` if `colorscheme` is set ([655ab06](https://github.com/nvim-neorocks/lz.n/commit/655ab06f4686371f07717c915b16eb4b18f6ef31))
* handler for lazy-loading colorschemes ([d4a2eeb](https://github.com/nvim-neorocks/lz.n/commit/d4a2eebb84b1c000a8388e167be3cb8f9d1edfe4))
