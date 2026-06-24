// SPDX-License-Identifier: MPL-2.0

/// Interfaces ABI/FFI inventory messages.

open Model

type interfacesMsg =
  | ScanInterfaces
  | InterfacesLoaded(result<string, string>)
  | SetIfaceCategory(interfacesCategory)
  /// TypeLL cross-panel type check result for ABI/FFI binding types.
  | TypeCheckResult(result<string, string>)
