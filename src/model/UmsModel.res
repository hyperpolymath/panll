// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Universal Modding Studio Model — types for the unified hub
/// orchestrating IDApTIK game content creation. Manages mod projects,
/// ABI validation, templates, assets, distribution, and API reference.

/// Category tabs for the UMS panel.
type umsCategory =
  | UmsProjects
  | UmsAbiValidator
  | UmsTemplates
  | UmsAssets
  | UmsDistribution
  | UmsApiReference

/// A mod project managed by the Universal Modding Studio.
type modProject = {
  /// Unique project identifier.
  id: string,
  /// Human-readable project name.
  name: string,
  /// Brief description of the mod project.
  description: string,
  /// Author of the mod project.
  author: string,
  /// Semantic version string.
  version: string,
  /// ISO 8601 creation timestamp.
  createdAt: string,
  /// ISO 8601 last modified timestamp.
  lastModified: string,
  /// Number of levels in the project.
  levelCount: int,
  /// Number of puzzles in the project.
  puzzleCount: int,
  /// Number of assets in the project.
  assetCount: int,
  /// Whether the project has passed ABI validation.
  validated: bool,
  /// Absolute path to the project directory on disk.
  projectPath: string,
}

/// Category of a mod template.
type templateCategory =
  | TemplateLevel
  | TemplatePuzzle
  | TemplateCampaign
  | TemplateAssetPack

/// A pre-built mod template for bootstrapping projects.
type modTemplate = {
  /// Unique template identifier.
  id: string,
  /// Human-readable template name.
  name: string,
  /// Brief description of what the template provides.
  description: string,
  /// Category classifying this template's purpose.
  category: templateCategory,
  /// Difficulty level of content produced by this template.
  difficulty: string,
  /// Path to the preview image for the template browser.
  previewImagePath: string,
}

/// Asset type classification for mod assets.
type modAssetType =
  | AssetSprite
  | AssetSound
  | AssetMap
  | AssetTileset
  | AssetAnimation
  | AssetScript

/// An asset belonging to a mod project.
type modAsset = {
  /// Unique asset identifier.
  id: string,
  /// Human-readable asset name.
  name: string,
  /// Type classification of this asset.
  assetType: modAssetType,
  /// Path to the asset file relative to the project.
  filePath: string,
  /// Size of the asset file in bytes.
  sizeBytes: int,
  /// List of project IDs or level IDs that reference this asset.
  usedIn: array<string>,
}

/// Result of validating a level against the Idris2 ABI proofs.
/// Each boolean field mirrors a specific proof obligation from the
/// IDApTIK ABI specification.
type abiValidationResult = {
  /// Level identifier that was validated.
  levelId: string,
  /// Guards-in-zones proof: every zone has its required guard entities.
  guardsInZones: bool,
  /// Defence-targets proof: all defence targets are reachable and valid.
  defenceTargetsValid: bool,
  /// Zone-ordering proof: zones are topologically sorted.
  zonesOrdered: bool,
  /// PBX-consistency proof: PBX routing tables are internally consistent.
  pbxConsistent: bool,
  /// Device-existence proof: all referenced devices exist in the level data.
  devicesExist: bool,
  /// Whether all proof obligations passed.
  allPassed: bool,
  /// ISO 8601 timestamp of when validation was run.
  validatedAt: string,
  /// Error messages for any failed proof obligations.
  errors: array<string>,
}

/// Platform target for mod distribution.
type distributionPlatform =
  | PlatformGithub
  | PlatformWorkshop
  | PlatformLocal
  | PlatformCustom

/// A distribution target for publishing mods.
type distributionTarget = {
  /// Target platform for distribution.
  platform: distributionPlatform,
  /// URL or path for the distribution endpoint.
  url: string,
  /// ISO 8601 timestamp of the last publish operation.
  lastPublished: string,
  /// Version string that was last published.
  version: string,
}

/// An entry in the modding API reference documentation.
type apiEntry = {
  /// Name of the API function or type.
  name: string,
  /// Category grouping (e.g. "Level", "Puzzle", "Asset", "VM").
  category: string,
  /// Type signature or function signature.
  signature: string,
  /// Human-readable description of the API entry.
  description: string,
  /// Usage example code snippet.
  example: string,
  /// Version since which this API has been available.
  since: string,
}

/// Root state for the Universal Modding Studio panel.
type umsState = {
  /// Currently active category tab.
  activeCategory: umsCategory,
  /// All mod projects known to the studio.
  projects: array<modProject>,
  /// Available mod templates.
  templates: array<modTemplate>,
  /// Assets for the currently selected project.
  assets: array<modAsset>,
  /// ID of the currently selected project, if any.
  selectedProjectId: option<string>,
  /// ABI validation results keyed by level.
  validationResults: array<abiValidationResult>,
  /// Distribution targets for the current project.
  distributionTargets: array<distributionTarget>,
  /// Modding API reference entries.
  apiEntries: array<apiEntry>,
  /// Text filter for searching within tabs.
  filterText: string,
  /// Whether a background operation is in progress.
  loading: bool,
  /// Current error message, if any.
  error: option<string>,
  /// Whether BoJ routing is enabled for cartridge integration.
  bojRouting: bool,
}
