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

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    pre-commit-hooks,
    gen-luarc,
    ...
  }: let
    name = "lze";
    perSystem = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    testshook = pkgs: {
      enable = true;
      name = "run-${name}-tests";
      entry = "${pkgs.writeShellScript "run-${name}-tests" ''
        set -e
        export HOME="$(mktemp -d)"
        gitroot="$(git rev-parse --show-toplevel)"
        if [ -z "$gitroot" ]; then
          echo "Error: Unable to determine Git root."
          exit 1
        fi
        ${pkgs.lib.getExe pkgs.neovim-unwrapped} --headless --cmd "luafile $gitroot/test.nvim" +qall!
      ''}";
    };
    pre-commit-check = pkgs: luarc:
      pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck = {
            enable = true;
          };
          lua-ls = {
            enable = true;
            settings.configuration = luarc;
          };
          editorconfig-checker.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration = {
              MD028 = false;
              MD060 = false;
            };
            excludes = [
              "CHANGELOG.md"
            ];
          };
          lemmy-docgen = let
            genpath = pkgs.lib.makeBinPath (
              with pkgs; [
                gawk
                git
                gnused
                coreutils
                lemmy-help
              ]
            );
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
          run-tests = testshook pkgs;
        };
      };
  in {
    overlays.default = final: prev: let
      packageOverrides = luaself: luaprev: {
        ${name} = luaself.callPackage (
          {buildLuarocksPackage}:
            buildLuarocksPackage {
              pname = name;
              version = "scm-1";
              knownRockspec = "${self}/${name}-scm-1.rockspec";
              src = self;
              checkPhase = ''
                runHook preInstallCheck
                export HOME=$(mktemp -d)
                ${final.lib.getExe final.neovim-unwrapped} --headless --cmd "luafile $src/test.nvim" +qall!
                runHook postInstallCheck
              '';
            }
        ) {};
      };

      lua5_1 = prev.lua5_1.override {
        inherit packageOverrides;
      };
      lua51Packages = final.lua5_1.pkgs;

      vimPlugins =
        prev.vimPlugins
        // {
          ${name} = final.neovimUtils.buildNeovimPlugin {
            pname = name;
            version = "dev";
            src = self;
          };
        };
    in {
      inherit
        lua5_1
        lua51Packages
        vimPlugins
        ;
    };

    devShells = perSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          gen-luarc.overlays.default
          self.overlays.default
        ];
        luarc = pkgs.mk-luarc {};
      in rec {
        default = pkgs.mkShell {
          name = "lze devShell";
          DEVSHELL = 0;
          shellHook = ''
            ${(pre-commit-check pkgs luarc).shellHook}
            ln -fs ${pkgs.luarc-to-json luarc} .luarc.json
          '';
          buildInputs =
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
            ]);
        };
        devShell = default;
      }
    );

    packages = perSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          self.overlays.default
        ];
      in rec {
        default = lze-vimPlugin;
        lze-luaPackage = pkgs.lua51Packages.${name};
        lze-vimPlugin = pkgs.vimPlugins.${name};
      }
    );

    checks = perSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          gen-luarc.overlays.default
          self.overlays.default
        ];
        nightlypkgs = pkgs.appendOverlays [inputs.neovim-nightly-overlay.overlays.default];
      in {
        pre-commit-check = pre-commit-check pkgs (pkgs.mk-luarc {});
        vimPlugins = pkgs.vimPlugins.${name}.overrideAttrs {doCheck = true;};
        luaPackage = pkgs.lua51Packages.${name}.overrideAttrs {doCheck = true;};
        vimPlugins-nigtly = nightlypkgs.vimPlugins.${name}.overrideAttrs {doCheck = true;};
        luaPackage-nigtly = nightlypkgs.lua51Packages.${name}.overrideAttrs {doCheck = true;};
        type-check-nightly = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls = {
              enable = true;
              settings.configuration = nightlypkgs.mk-luarc {};
            };
            run-tests = testshook pkgs;
          };
        };
      }
    );
  };
}
