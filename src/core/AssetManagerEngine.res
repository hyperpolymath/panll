// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Asset Manager Engine — pure computation and helpers for managing
/// PixiJS sprites, sounds, level templates, and other game assets.
///
/// Provides default state, tab labels, and utility functions for counting
/// assets by kind, computing total size, formatting file sizes, and
/// filtering assets by text and kind.

open AssetManagerModel

/// Default state for the Asset Manager panel.
let defaultState: assetManagerState = {
  activeTab: Browse,
  assets: [],
  collections: [],
  filter: "",
  kindFilter: None,
  selectedAsset: None,
  importing: false,
  error: None,
}

/// Human-readable label for an asset manager category tab.
let tabLabel = (cat: assetManagerCategory): string =>
  switch cat {
  | Browse => "Browse"
  | Import => "Import"
  | Collections => "Collections"
  | Usage => "Usage"
  }

/// All category tabs in display order.
let allTabs: array<assetManagerCategory> = [Browse, Import, Collections, Usage]

/// Count assets matching a given kind.
let countByKind = (assets: array<gameAsset>, kind: assetKind): int =>
  assets->Array.filter(a => a.kind === kind)->Array.length

/// Compute total size in bytes across all assets.
let totalSizeBytes = (assets: array<gameAsset>): int =>
  assets->Array.reduce(0, (acc, a) => acc + a.sizeBytes)

/// Format a byte count as a human-readable file size string.
/// Produces "B", "KB", "MB", or "GB" suffixes as appropriate.
let formatFileSize = (bytes: int): string => {
  let b = Int.toFloat(bytes)
  if b < 1024.0 {
    `${Int.toString(bytes)} B`
  } else if b < 1048576.0 {
    let kb = b /. 1024.0
    `${Float.toFixedWithPrecision(kb, ~digits=1)} KB`
  } else if b < 1073741824.0 {
    let mb = b /. 1048576.0
    `${Float.toFixedWithPrecision(mb, ~digits=1)} MB`
  } else {
    let gb = b /. 1073741824.0
    `${Float.toFixedWithPrecision(gb, ~digits=2)} GB`
  }
}

/// Filter assets by text query and optional kind filter.
/// Text search matches against asset name (case-insensitive).
let filterAssets = (
  assets: array<gameAsset>,
  textFilter: string,
  kindFilter: option<assetKind>,
): array<gameAsset> => {
  let lower = textFilter->String.toLowerCase
  assets->Array.filter(a => {
    let matchesText = lower === "" || a.name->String.toLowerCase->String.includes(lower)
    let matchesKind = switch kindFilter {
    | None => true
    | Some(k) => a.kind === k
    }
    matchesText && matchesKind
  })
}
