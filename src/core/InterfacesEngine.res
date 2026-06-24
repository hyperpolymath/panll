// SPDX-License-Identifier: MPL-2.0

/// PanLL Interfaces Engine — pure computation for ABI/FFI inventory.

open InterfacesModel

let categoryLabel = (cat: interfacesCategory): string =>
  switch cat {
  | IfaceDashboard => "Dashboard"
  | IfaceAbi => "ABI (Idris2)"
  | IfaceFfi => "FFI (Zig)"
  | IfaceBindings => "Bindings"
  }

/// Total ABI exports across all definitions.
let totalAbiExports = (defs: array<abiDefinition>): int =>
  defs->Array.reduce(0, (acc, d) => acc + d.exportCount)

/// Total believe_me count (should always be 0 in proven-servers).
let totalBelieveMe = (defs: array<abiDefinition>): int =>
  defs->Array.reduce(0, (acc, d) => acc + d.believeMeCount)

/// Overall verification rate.
let verificationRate = (defs: array<abiDefinition>): float => {
  if Array.length(defs) > 0 {
    let verified = defs->Array.filter(d => d.verified)->Array.length
    Int.toFloat(verified) /. Int.toFloat(Array.length(defs))
  } else {
    0.0
  }
}

/// Average binding coverage across all languages.
let avgCoverage = (bindings: array<bindingCoverage>): float => {
  if Array.length(bindings) > 0 {
    bindings->Array.map(b => b.coverage)->Array.reduce(0.0, (a, b) => a +. b) /.
      Int.toFloat(Array.length(bindings))
  } else {
    0.0
  }
}

let defaultState: interfacesState = {
  loaded: false,
  loading: false,
  error: None,
  abiDefs: [],
  ffiImpls: [],
  bindings: [],
  activeCategory: IfaceDashboard,
  totalBelieveMe: 0,
}
