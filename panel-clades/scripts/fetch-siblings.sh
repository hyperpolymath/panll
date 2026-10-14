#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Fetch the sibling repositories the panel-clades ABI consumes, at pinned
# commits (pattern: residual-evidence-types / choreographic-types).
#
#   typed-wasm — its Idris2 grade kernel (src/abi/TypedWasm/ABI/ResourceAlgebra*,
#                transcribed from hyperpolymath/resource-algebra @ cf9235c) is
#                imported by PanelClades.ABI.Grades, never re-declared.
#
# Pinned at typed-wasm main 117bbf8 (#274; the kernel landed in #271, its
# Nat lemmas such as maxLub in #273).  Re-pin deliberately, one commit per
# pin.  Override for an experiment with
#   TYPED_WASM_COMMIT=<sha> panel-clades/scripts/fetch-siblings.sh
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

TYPED_WASM_COMMIT="${TYPED_WASM_COMMIT:-117bbf895b513673ba06eb6c4ebb0e26e276e295}"

fetch() { # fetch <name> <commit>
  local name="$1" commit="$2" dir="_build/dependencies/$1"
  mkdir -p _build/dependencies
  if [ ! -d "$dir/.git" ]; then
    git clone --quiet "https://github.com/hyperpolymath/${name}.git" "$dir"
  fi
  if ! git -C "$dir" cat-file -e "${commit}^{commit}" 2>/dev/null; then
    git -C "$dir" fetch --quiet origin
  fi
  git -C "$dir" checkout --quiet --detach "$commit"
  local got
  got="$(git -C "$dir" rev-parse HEAD)"
  case "$got" in
    "$commit"*) echo "${name} at ${got}" ;;
    *) echo "ERROR: ${name} resolved to ${got}, expected ${commit}" >&2; exit 1 ;;
  esac
}

fetch typed-wasm "$TYPED_WASM_COMMIT"
