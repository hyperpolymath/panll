// SPDX-License-Identifier: PMPL-1.0-or-later

/// Interfaces ABI/FFI inventory messages.

open Model

type interfacesMsg =
  | ScanInterfaces
  | InterfacesLoaded(result<string, string>)
  | SetIfaceCategory(interfacesCategory)
  /// TypeLL cross-panel type check result for ABI/FFI binding types.
  | TypeCheckResult(result<string, string>)
