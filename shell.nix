let
  pkgs = import (import ./vm/sources.nix).nixpkgs { };
in
pkgs.mkShellNoCC {
  packages = [
    pkgs.jq
    pkgs.zstd
  ];
}
