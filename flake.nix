{
  description = "Add laziness to your favourite plugin manager!";
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };

    neorocks.url = "github:nvim-neorocks/neorocks";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    pre-commit-hooks,
    neorocks,
    gen-luarc,
    ...
  }: let
    name = "lze";

    pkg-overlay = import ./nix/pkg-overlay.nix {
      inherit name self;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        ci-overlay = import ./nix/ci-overlay.nix {
          inherit self;
          plugin-name = name;
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            gen-luarc.overlays.default
            neorocks.overlays.default
            ci-overlay
            pkg-overlay
          ];
        };

        luarc = pkgs.mk-luarc {
          nvim = pkgs.neovim-nightly;
        };
        luarccurrent = pkgs.mk-luarc {
          nvim = pkgs.neovim;
        };

        type-check-nightly = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls = {
              enable = true;
              settings.configuration = luarc;
            };
          };
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck = {
              enable = true;
            };
            lua-ls = {
              enable = true;
              settings.configuration = luarccurrent;
            };
            editorconfig-checker.enable = true;
            markdownlint = {
              enable = true;
              excludes = [
                "CHANGELOG.md"
              ];
            };
            lemmy-docgen = let
              genpath = pkgs.lib.makeBinPath (with pkgs; [
                gawk
                git
                gnused
                coreutils
                lemmy-help
              ]);
              lemmyscript = pkgs.writeShellScript "lemmy-helper" ''
                export PATH="${genpath}:$PATH"
                gitroot="$(git rev-parse --show-toplevel)"
                if [ -z "$gitroot" ]; then
                  echo "Error: Unable to determine Git root."
                  exit 1
                fi
                maindoc="$(realpath "$gitroot/doc/lze.txt")"
                luamain="$(realpath "$gitroot/lua/lze/init.lua")"
                luameta="$(realpath "$gitroot/lua/lze/meta.lua")"
                mkdir -p "$(dirname "$maindoc")"
                export DOCOUT=$(mktemp)
                lemmy-help "$luamain" > "$DOCOUT"
                export BASHCACHE=$(mktemp)
                modeline="vim:tw=78:ts=8:noet:ft=help:norl:"
                sed "/$modeline/d" "$DOCOUT" > $BASHCACHE
                echo "                                             *lze.types*" >> $BASHCACHE
                echo "" >> $BASHCACHE
                echo ">lua" >> $BASHCACHE
                awk '{print "  " $0}' "$luameta" >> $BASHCACHE
                echo "<" >> $BASHCACHE
                echo "==============================================================================" >> $BASHCACHE
                echo "$modeline" >> $BASHCACHE
                cat "$BASHCACHE" > "$maindoc"
                rm "$BASHCACHE"
                rm "$DOCOUT"
              '';
            in {
              enable = true;
              name = "lemmy-docgen";
              entry = "${lemmyscript}";
            };
          };
        };

        devShell = pkgs.mkShell {
          name = "lze devShell";
          DEVSHELL = 0;
          shellHook = ''
            ${pre-commit-check.shellHook}
            ln -fs ${pkgs.luarc-to-json luarc} .luarc.json
          '';
          buildInputs =
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
              busted-nlua
            ]);
        };
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = lze-vimPlugin;
          lze-luaPackage = pkgs.lua51Packages.${name};
          lze-vimPlugin = pkgs.vimPlugins.${name};
        };

        checks = {
          inherit
            pre-commit-check
            type-check-nightly
            ;
          inherit
            (pkgs)
            nvim-nightly-tests
            ;
        };
      };
      flake = {
        overlays.default = pkg-overlay;
      };
    };
}
