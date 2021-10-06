{
  description = "An algebraic data type for describing OpenSCAD models";
  nixConfig.bash-prompt = ''[nix-develop]$ '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};

        packageName = "openscad";

        haskellPackages = pkgs.haskellPackages.override {
          inherit ((self.overlay.${system} {} pkgs).${packageName}) overrides;
        };

        chain-overrides = new: old:
          builtins.foldl' (upd: overrides: upd // overrides new (old // upd)) old;

        overrides = new: old: {
          ${packageName} = old.callCabal2nix packageName self {
          };
        };

      in {


        overlay = final: prev: {
          ${packageName}.overrides = new: old: chain-overrides new old [
            overrides
          ];
        };


        packages.${packageName} = haskellPackages.${packageName};

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            ghcid
            cabal-install

            (haskellPackages.ghcWithPackages (h: with h; [
            ]))
          ];
          inputsFrom = [ self.defaultPackage ];
          # inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
