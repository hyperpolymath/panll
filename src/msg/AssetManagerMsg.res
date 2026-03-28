// SPDX-License-Identifier: PMPL-1.0-or-later

/// Asset Manager messages -- PixiJS sprites, sounds, level templates.

open Model

type assetManagerMsg =
  | SetAmCategory(assetManagerCategory)
  | AmStarted
  | AmCompleted(result<string, string>)
  | DismissAmError
