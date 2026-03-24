# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
#
# Nix flake development environment for panll.
# Usage: nix develop
{
  description = "PanLL — neurosymbolic panel layout system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Deno — runtime and package management
            deno

            # Rust — core panel engine
            rustc
            cargo
            clippy
            rustfmt

            # Zig — FFI implementation
            zig

            # Build tooling
            pkg-config
            gnumake
          ];

          shellHook = ''
            echo "panll dev shell — deno + cargo + zig"
          '';
        };
      });
}
