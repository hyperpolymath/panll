# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Nix flake for PanLL eNSAID
#
# NOTE: guix.scm is the PRIMARY development environment. This flake is provided
# as a FALLBACK for contributors who use Nix instead of Guix. The .envrc checks
# for Guix first, then falls back to Nix.
#
# Usage:
#   nix develop          # Enter development shell
#   nix build            # Build the project
#   nix flake check      # Run checks
#   nix flake show       # Show flake outputs
#
# With direnv (.envrc already configured):
#   direnv allow         # Auto-enters shell on cd
#
# TODO: Replace PanLL eNSAID and {{PROJECT_DESCRIPTION}} with actual values.

{
  description = "PanLL eNSAID — RSR-compliant project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Common development tools present in every RSR project.
        commonTools = with pkgs; [
          git
          just
          nickel
          curl
          bash
          coreutils
        ];

        # ---------------------------------------------------------------
        # Language-specific packages: uncomment the stacks you need.
        # ---------------------------------------------------------------
        #
        # Rust:
        #   rustc cargo clippy rustfmt rust-analyzer
        #
        # Elixir:
        #   elixir erlang
        #
        # Gleam:
        #   gleam erlang
        #
        # Zig:
        #   zig zls
        #
        # Haskell:
        #   ghc cabal-install haskell-language-server
        #
        # Idris2:
        #   idris2
        #
        # OCaml:
        #   ocaml dune_3 ocaml-lsp
        #
        # ReScript (via Deno):
        #   deno
        #
        # Julia:
        #   julia
        #
        # Ada/SPARK:
        #   gnat gprbuild
        #
        # ---------------------------------------------------------------
        languageTools = with pkgs; [
          # TODO: Uncomment or add packages for your stack.
          # Example for a Rust project:
          # rustc
          # cargo
          # clippy
          # rustfmt
          # rust-analyzer
        ];

      in
      {
        # ---------------------------------------------------------------
        # Development shell — `nix develop`
        # ---------------------------------------------------------------
        devShells.default = pkgs.mkShell {
          name = "PanLL eNSAID-dev";

          buildInputs = commonTools ++ languageTools;

          # Environment variables available inside the shell.
          env = {
            PROJECT_NAME = "PanLL eNSAID";
            RSR_TIER = "infrastructure";
          };

          shellHook = ''
            echo ""
            echo "  PanLL eNSAID — development shell"
            echo "  Nix:    $(nix --version 2>/dev/null || echo 'unknown')"
            echo "  Just:   $(just --version 2>/dev/null || echo 'not found')"
            echo ""
            echo "  Run 'just' to see available recipes."
            echo ""

            # Source .envrc manually when direnv is not managing the shell.
            # This keeps project env vars (PROJECT_NAME, DATABASE_URL, etc.)
            # consistent whether you enter via 'nix develop' or 'direnv allow'.
            if [ -z "''${DIRENV_IN_ENVRC:-}" ] && [ -f .envrc ]; then
              # Only source the non-nix parts to avoid recursion.
              export PROJECT_NAME="PanLL eNSAID"
              export RSR_TIER="infrastructure"
              if [ -f .env ]; then
                set -a
                . .env
                set +a
              fi
            fi
          '';
        };

        # ---------------------------------------------------------------
        # Package — `nix build`
        # ---------------------------------------------------------------
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "PanLL eNSAID";
          version = "0.1.0";

          src = self;

          # TODO: Replace with real build instructions.
          # Examples:
          #
          # Rust (use rustPlatform.buildRustPackage instead of stdenv):
          #   packages.default = pkgs.rustPlatform.buildRustPackage { ... };
          #
          # Elixir (use mixRelease):
          #   packages.default = pkgs.beamPackages.mixRelease { ... };
          #
          # Zig:
          #   buildPhase = "zig build -Doptimize=ReleaseSafe";

          buildPhase = ''
            echo "TODO: Add build commands for PanLL eNSAID"
          '';

          installPhase = ''
            mkdir -p $out/share/doc
            cp README.adoc $out/share/doc/ 2>/dev/null || true
          '';

          meta = with pkgs.lib; {
            description = "{{PROJECT_DESCRIPTION}}";
            homepage = "https://github.com/hyperpolymath/PanLL eNSAID";
            license = licenses.mpl20; # MPL-2.0 extends MPL-2.0
            maintainers = [];
            platforms = [ "x86_64-linux" "aarch64-linux" ];
          };
        };
      }
    );
}
