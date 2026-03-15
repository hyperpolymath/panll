// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Asset Manager Model — types for managing PixiJS sprites, sounds,
/// level templates, and other game assets.
///
/// Provides browsing, importing, tagging, and usage tracking for all
/// asset types used in IDApTIK levels. Assets are organised into
/// named collections and can be filtered by kind and tags.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Classification of game asset types.
type assetKind =
  /// Single sprite image (PNG, WebP).
  | Sprite
  /// Sprite sheet with frame definitions.
  | SpriteSheet
  /// Sound effect (WAV, OGG).
  | Sound
  /// Background music track (OGG, MP3).
  | Music
  /// Font file (TTF, WOFF2).
  | Font
  /// Saved level template for reuse.
  | LevelTemplate
  /// Particle effect definition.
  | ParticleEffect

/// A single game asset with metadata and usage tracking.
type gameAsset = {
  /// Unique identifier for this asset.
  id: string,
  /// Human-readable asset name.
  name: string,
  /// Classification of this asset.
  kind: assetKind,
  /// Relative path to the asset file.
  path: string,
  /// File size in bytes.
  sizeBytes: int,
  /// Pixel dimensions for image assets (width, height); None for non-image.
  dimensions: option<(int, int)>,
  /// Tags for categorisation and search.
  tags: array<string>,
  /// IDs of levels that reference this asset.
  usedInLevels: array<string>,
  /// ISO 8601 timestamp of when the asset was imported.
  importedAt: string,
}

/// A named collection of related assets.
type assetCollection = {
  /// Collection name (e.g., "Guard Sprites", "Ambient Sounds").
  name: string,
  /// Assets belonging to this collection.
  assets: array<gameAsset>,
  /// Human-readable description of the collection's purpose.
  description: string,
}

/// Category tabs for the Asset Manager panel.
type assetManagerCategory =
  /// Browse and search all imported assets.
  | Browse
  /// Import new assets from disk.
  | Import
  /// Manage named asset collections.
  | Collections
  /// View asset usage across levels.
  | Usage

/// Root state for the Asset Manager panel.
type assetManagerState = {
  /// Active category tab.
  activeTab: assetManagerCategory,
  /// All imported game assets.
  assets: array<gameAsset>,
  /// Named asset collections.
  collections: array<assetCollection>,
  /// Current text filter for searching assets.
  filter: string,
  /// Filter by asset kind (None = show all).
  kindFilter: option<assetKind>,
  /// ID of the currently selected asset (if any).
  selectedAsset: option<string>,
  /// Whether an import operation is in progress.
  importing: bool,
  /// Error message (if any).
  error: option<string>,
}
