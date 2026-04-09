# Contributing guide

Contributions are more than welcome!

## Commit messages / PR title

Please ensure your pull request title conforms to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## CI

CI checks are run using [`nix`](https://nixos.org/download.html#download-nix).

## Development

### Dev environment

We use the following tools:

#### Formatting

- [`.editorconfig`](https://editorconfig.org/) (with [`editorconfig-checker`](https://github.com/editorconfig-checker/editorconfig-checker))
- [`stylua`](https://github.com/JohnnyMorganz/StyLua) [Lua]
- [`alejandra`](https://github.com/kamadorueda/alejandra) [Nix]

#### Linting

- [`luacheck`](https://github.com/mpeterv/luacheck) [Lua]
- [`markdownlint`](https://github.com/DavidAnson/markdownlint) [Markdown]

#### Static type checking

- [`lua-language-server`](https://github.com/LuaLS/lua-language-server/wiki/Diagnosis-Report#create-a-report)

### Nix devShell

- Requires [flakes](https://wiki.nixos.org/wiki/Flakes) to be enabled.

This project provides a `flake.nix` that can
bootstrap all of the above development tools.

To enter a development shell:

```console
nix develop
```

To apply formatting, while in a devShell, run

```console
pre-commit run --all
```

If you use [`direnv`](https://direnv.net/),
just run `direnv allow` and you will be dropped in this devShell.

### Running tests

Have `nvim` command installed to your `PATH`
(must be usable via the interpreter line `#!/usr/bin/env -S nvim -l`)

Navigate to the root of the repository and run `./test.nvim`

They will also ran as part of the pre-commit checks.

### Running tests and checks with Nix

If you just want to run all checks that are available, run:

```console
nix flake check -L --option sandbox false
```

To run tests locally, using Nix:

```console
nix build .#checks.<your-system>.integration-nightly -L --option sandbox false
```

For example:

```console
nix build .#checks.x86_64-linux.integration-nightly -L --option sandbox false
```

For formatting and linting:

```console
nix build .#checks.<your-system>.pre-commit-check -L
```

For static type checking:

```console
nix build .#checks.<your-system>.type-check-nightly -L
```
