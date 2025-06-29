# Changelog

## [0.11.4](https://github.com/BirdeeHub/lze/compare/v0.11.3...v0.11.4) (2025-06-19)


### Bug Fixes

* **deprecate:** removed lze.x, which has done nothing but warn for 5 months ([a68ab6b](https://github.com/BirdeeHub/lze/commit/a68ab6b52756b0d1650ae79eb6442dd278cff435))

## [0.11.3](https://github.com/BirdeeHub/lze/compare/v0.11.2...v0.11.3) (2025-05-25)


### Bug Fixes

* **on_require:** improved formatting of error message ([6551328](https://github.com/BirdeeHub/lze/commit/6551328084a7ff79f61665d4e389524b2b058e56))

## [0.11.2](https://github.com/BirdeeHub/lze/compare/v0.11.1...v0.11.2) (2025-05-25)


### Bug Fixes

* **feature:** improved how on_require handler works internally ([7ff9e10](https://github.com/BirdeeHub/lze/commit/7ff9e104c41ecc585035cc3683ac92a308fefc3f))

## [0.11.1](https://github.com/BirdeeHub/lze/compare/v0.11.0...v0.11.1) (2025-04-08)


### Bug Fixes

* **on_require:** now properly propagates error messages ([efbd778](https://github.com/BirdeeHub/lze/commit/efbd778e1b5e9d98ecc31298256e3ff5bcfed0d4))

## [0.11.0](https://github.com/BirdeeHub/lze/compare/v0.10.0...v0.11.0) (2025-03-30)


### Features

* **vim.g.lze.injects:** set a default value for a field, visible to handlers ([4ef81ea](https://github.com/BirdeeHub/lze/commit/4ef81ea502884ab3b3415d5cf3f5b33dbc95206b))

## [0.10.0](https://github.com/BirdeeHub/lze/compare/v0.9.1...v0.10.0) (2025-03-25)


### Features

* **version:** remove vim.iter to support older nvim versions ([4efeb2f](https://github.com/BirdeeHub/lze/commit/4efeb2f33ab12f6f500d9392ab80be9b19026b0c))

## [0.9.1](https://github.com/BirdeeHub/lze/compare/v0.9.0...v0.9.1) (2025-03-21)


### Bug Fixes

* **beforeAll:** once again beforeAll ([da9a0c8](https://github.com/BirdeeHub/lze/commit/da9a0c8e44162fecd1b03c41dbb55e133f8bc65f))

## [0.9.0](https://github.com/BirdeeHub/lze/compare/v0.8.1...v0.9.0) (2025-03-21)


### Features

* **handler:** add and modify hooks can return a function to be deferred ([a43c98e](https://github.com/BirdeeHub/lze/commit/a43c98e67e357b9c6af1fc0592fc3b8533d1af8b))

## [0.8.1](https://github.com/BirdeeHub/lze/compare/v0.8.0...v0.8.1) (2025-03-07)


### Bug Fixes

* **event:** ft loop ([308290b](https://github.com/BirdeeHub/lze/commit/308290b31b77c9f24eb63abbd07394f1d1797ae2))
* **event:** ft loop ([5ba6ccf](https://github.com/BirdeeHub/lze/commit/5ba6ccfc854c876902a1a29bfd39cfb3b141370b))

## [0.8.0](https://github.com/BirdeeHub/lze/compare/v0.7.11...v0.8.0) (2025-02-19)


### Features

* **lze.h:** lze.h[spec_field].handler_exported_function() ([67220ae](https://github.com/BirdeeHub/lze/commit/67220aeb7dc079d4b45d875e0dbdab842718e956))

## [0.7.11](https://github.com/BirdeeHub/lze/compare/v0.7.10...v0.7.11) (2025-02-13)


### Bug Fixes

* **trigger_load:** before can no longer alter load ([ed7f60e](https://github.com/BirdeeHub/lze/commit/ed7f60e4d1f21520028c2cfd8a413572fb69a819))

## [0.7.10](https://github.com/BirdeeHub/lze/compare/v0.7.9...v0.7.10) (2025-02-13)


### Bug Fixes

* **cmd:** doesnt error when asked to delete a command that doesnt exist ([4d0ef68](https://github.com/BirdeeHub/lze/commit/4d0ef68a08cf17a4ecc41201bb5716af7020829b))

## [0.7.9](https://github.com/BirdeeHub/lze/compare/v0.7.8...v0.7.9) (2025-02-08)


### Bug Fixes

* **modify:** modify now runs before is lazy so that it can know the original setting ([870cfc3](https://github.com/BirdeeHub/lze/commit/870cfc3fb302c0929cf86cf31c19a8cdd4aacaa3))

## [0.7.8](https://github.com/BirdeeHub/lze/compare/v0.7.7...v0.7.8) (2025-02-08)


### Bug Fixes

* **modify:** modify now runs before is lazy so that it can know the original setting ([ab2282d](https://github.com/BirdeeHub/lze/commit/ab2282d3745b6e6f9b61cfa42c8165124dbd9bb4))

## [0.7.7](https://github.com/BirdeeHub/lze/compare/v0.7.6...v0.7.7) (2025-02-08)


### Bug Fixes

* **trigger_load:** further improve error handling ([97d3a29](https://github.com/BirdeeHub/lze/commit/97d3a29cc4d4d123d0e8c7892d56eccd85e2352f))

## [0.7.6](https://github.com/BirdeeHub/lze/compare/v0.7.5...v0.7.6) (2025-02-08)


### Bug Fixes

* **startup_plugins:** errors in startup_plugins are now handled more gracefully ([2cc19e6](https://github.com/BirdeeHub/lze/commit/2cc19e6c9eedc7f0a8efc15b69dd9f209bdf0d53))

## [0.7.5](https://github.com/BirdeeHub/lze/compare/v0.7.4...v0.7.5) (2025-02-07)


### Bug Fixes

* **warning:** made warning less verbose ([c76bc2c](https://github.com/BirdeeHub/lze/commit/c76bc2c885ec02ac53f0b2889b6c9d1601d163a5))

## [0.7.4](https://github.com/BirdeeHub/lze/compare/v0.7.3...v0.7.4) (2025-02-07)


### Bug Fixes

* **load_return:** lze.load returns duplicate plugins, not a list of strings ([48b335a](https://github.com/BirdeeHub/lze/commit/48b335a06b780d51d4469b31f74a27e1999d13e3))

## [0.7.3](https://github.com/BirdeeHub/lze/compare/v0.7.2...v0.7.3) (2025-02-07)


### Bug Fixes

* **internal:** performance ([c6b9067](https://github.com/BirdeeHub/lze/commit/c6b9067783b8ae96fa02b604b23ba5fcdf6dfdce))

## [0.7.2](https://github.com/BirdeeHub/lze/compare/v0.7.1...v0.7.2) (2025-02-07)


### Bug Fixes

* **internal:** prevent misuse of internal functions ([09213be](https://github.com/BirdeeHub/lze/commit/09213beb1b7ddf256e8c0227796a167f753d34ad))

## [0.7.1](https://github.com/BirdeeHub/lze/compare/v0.7.0...v0.7.1) (2025-02-07)


### Bug Fixes

* **internal:** prevent misuse of internal functions ([f5d753e](https://github.com/BirdeeHub/lze/commit/f5d753e4f7d544add3352e721f24cc05d1cf621c))

## [0.7.0](https://github.com/BirdeeHub/lze/compare/v0.6.3...v0.7.0) (2025-02-05)


### Features

* **handlers:** lze.remove_handlers(string|string[]):lze.Handler[] ([9fd946f](https://github.com/BirdeeHub/lze/commit/9fd946fc3109f685fbebff74b785c0d596cb40b5))

## [0.6.3](https://github.com/BirdeeHub/lze/compare/v0.6.2...v0.6.3) (2025-01-26)


### Bug Fixes

* **nop:** support for nop keybindings ([d0cc725](https://github.com/BirdeeHub/lze/commit/d0cc72559b81b1c7588e539a5392bfa7d4f28120))

## [0.6.2](https://github.com/BirdeeHub/lze/compare/v0.6.1...v0.6.2) (2025-01-26)


### Bug Fixes

* **handler.spec_field:** false is now an allowed value ([586f744](https://github.com/BirdeeHub/lze/commit/586f7448b11f213510318b3b8c9f594c5576919f))

## [0.6.1](https://github.com/BirdeeHub/lze/compare/v0.6.0...v0.6.1) (2025-01-26)


### Bug Fixes

* **handler.spec_field:** false is now an allowed value ([8fd70c3](https://github.com/BirdeeHub/lze/commit/8fd70c3a51523a8eece4df5995f4b3af6e5c237a))

## [0.6.0](https://github.com/BirdeeHub/lze/compare/v0.5.0...v0.6.0) (2025-01-26)


### Features

* **plz_ignore:** removed loadbearing comment ([b45c6e5](https://github.com/BirdeeHub/lze/commit/b45c6e546481a130bd6eaf0a9c3e6f6c445df451))

## [0.5.0](https://github.com/BirdeeHub/lze/compare/v0.4.6...v0.5.0) (2025-01-26)


### Features

* **lze.x by default:** lze.x now included by default. ([a49ff1f](https://github.com/BirdeeHub/lze/commit/a49ff1fe9afbea0fe4beff106baad5438ab44027))

## [0.4.6](https://github.com/BirdeeHub/lze/compare/v0.4.5...v0.4.6) (2025-01-26)


### Bug Fixes

* **beforeAll:** fixed unintended spec mutability ([01cf37f](https://github.com/BirdeeHub/lze/commit/01cf37fc70ab946045580a9d16cbd57cc33926da))

## [0.4.5](https://github.com/BirdeeHub/lze/compare/v0.4.4...v0.4.5) (2024-12-17)


### Bug Fixes

* **query_state:** depreciated query_state ([4b9e2ce](https://github.com/BirdeeHub/lze/commit/4b9e2ce774f6241ce7ec675145f9139f3395dd3f))

## [0.4.4](https://github.com/BirdeeHub/lze/compare/v0.4.3...v0.4.4) (2024-11-04)


### Performance Improvements

* **register_handlers:** improved it further ([041aa70](https://github.com/BirdeeHub/lze/commit/041aa70cb606b2a1a22b7d714656b3d7b15af706))

## [0.4.3](https://github.com/BirdeeHub/lze/compare/v0.4.2...v0.4.3) (2024-11-04)


### Performance Improvements

* **register_handlers:** improved it further ([0b25e31](https://github.com/BirdeeHub/lze/commit/0b25e317477f87a48c67c5ef1aa1426a54f2f79c))

## [0.4.2](https://github.com/BirdeeHub/lze/compare/v0.4.1...v0.4.2) (2024-11-03)


### Performance Improvements

* **register_handlers:** removed a loop from processing of spec ([cc73ce3](https://github.com/BirdeeHub/lze/commit/cc73ce303e97e59ad5c2e3d1362e0f69730f17ec))

## [0.4.1](https://github.com/BirdeeHub/lze/compare/v0.4.0...v0.4.1) (2024-11-03)


### Performance Improvements

* **register_handlers:** removed a loop processing the spec ([8f8a62a](https://github.com/BirdeeHub/lze/commit/8f8a62ae54e41f7bbb5f52a39b968b225d9e225d))

## [0.4.0](https://github.com/BirdeeHub/lze/compare/v0.3.0...v0.4.0) (2024-11-03)


### Features

* **handler.set_lazy:** ability to choose if a handler affects laziness ([58f3ff4](https://github.com/BirdeeHub/lze/commit/58f3ff4936396c556efedca33bf984169a24d1a3))

## [0.3.0](https://github.com/BirdeeHub/lze/compare/v0.2.0...v0.3.0) (2024-11-03)


### Features

* **lze.state:** added ability to snapshot state ([0474c38](https://github.com/BirdeeHub/lze/commit/0474c38e4c91020c2894adcbbb67ca46a837ba82))

## [0.2.0](https://github.com/BirdeeHub/lze/compare/v0.1.4...v0.2.0) (2024-11-02)


### Features

* **lze.State:** cheaper state query ([4b0fd7a](https://github.com/BirdeeHub/lze/commit/4b0fd7adb49835641bc6a01b3ea08066498e95a2))

## [0.1.4](https://github.com/BirdeeHub/lze/compare/v0.1.3...v0.1.4) (2024-10-28)


### Bug Fixes

* **cmd:** dummy cmd hanging around ([7a2649f](https://github.com/BirdeeHub/lze/commit/7a2649fe921d54f16910e1c062bb0c6be55c0c0a))

## [0.1.3](https://github.com/BirdeeHub/lze/compare/v0.1.2...v0.1.3) (2024-10-24)


### Performance Improvements

* **spec.parse:** slight improvement on last change ([d919d28](https://github.com/BirdeeHub/lze/commit/d919d28faab5edded746d1c2dd8bc12473a42af8))

## [0.1.2](https://github.com/BirdeeHub/lze/compare/v0.1.1...v0.1.2) (2024-10-24)


### Bug Fixes

* **lazy attribute:** spec.lazy = false is now authoritative ([e4b03d5](https://github.com/BirdeeHub/lze/commit/e4b03d557b5fae3ff563895c87143a30cba113a0))

## [0.1.1](https://github.com/BirdeeHub/lze/compare/v0.1.0...v0.1.1) (2024-09-03)


### Bug Fixes

* **nested events:** triggering events from after of event trigger ([f77d182](https://github.com/BirdeeHub/lze/commit/f77d182735f0df27c482b5894d2e73cd418cd6c2))

## [0.1.0](https://github.com/BirdeeHub/lze/compare/v0.0.0...v0.1.0) (2024-08-31)


### Features

* **release-0.0.1:** has tests and readme, release-worthy? ([c07c96d](https://github.com/BirdeeHub/lze/commit/c07c96db7fe71d4434e550d43ff89de2320297fe))
