// SPDX-License-Identifier: MPL-2.0

/// Asset Manager messages -- PixiJS sprites, sounds, level templates.

open Model

type assetManagerMsg =
  | SetAmCategory(assetManagerCategory)
  | AmStarted
  | AmCompleted(result<string, string>)
  | DismissAmError
