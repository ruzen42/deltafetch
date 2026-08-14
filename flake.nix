{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            haskell.compiler.native-bignum.ghc9103
            cabal-install
            stack
            git
            zlib
            pkg-config
          ];
        };

        packages.default = pkgs.haskellPackages.callCabal2nix "deltafetch" ./. {};
      });
}

