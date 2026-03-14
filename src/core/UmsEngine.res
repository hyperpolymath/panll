// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Universal Modding Studio Engine — pure computation and helpers
/// for the UMS panel. Category labels, colour mappings, filtering,
/// statistics, and default state.

open UmsModel

/// Human-readable label for each UMS category tab.
let categoryLabel = (cat: umsCategory): string =>
  switch cat {
  | UmsProjects => "Projects"
  | UmsAbiValidator => "ABI Validator"
  | UmsTemplates => "Templates"
  | UmsAssets => "Assets"
  | UmsDistribution => "Distribution"
  | UmsApiReference => "API Reference"
  }

/// Icon hint for each UMS category tab (emoji-free text glyph).
let categoryIcon = (cat: umsCategory): string =>
  switch cat {
  | UmsProjects => "[P]"
  | UmsAbiValidator => "[V]"
  | UmsTemplates => "[T]"
  | UmsAssets => "[A]"
  | UmsDistribution => "[D]"
  | UmsApiReference => "[R]"
  }

/// Human-readable label for a template category.
let templateCategoryLabel = (cat: templateCategory): string =>
  switch cat {
  | TemplateLevel => "Level"
  | TemplatePuzzle => "Puzzle"
  | TemplateCampaign => "Campaign"
  | TemplateAssetPack => "Asset Pack"
  }

/// Tailwind colour class for a template category.
let templateCategoryColour = (cat: templateCategory): string =>
  switch cat {
  | TemplateLevel => "text-cyan-400"
  | TemplatePuzzle => "text-amber-400"
  | TemplateCampaign => "text-purple-400"
  | TemplateAssetPack => "text-emerald-400"
  }

/// Human-readable label for a mod asset type.
let assetTypeLabel = (t: modAssetType): string =>
  switch t {
  | AssetSprite => "Sprite"
  | AssetSound => "Sound"
  | AssetMap => "Map"
  | AssetTileset => "Tileset"
  | AssetAnimation => "Animation"
  | AssetScript => "Script"
  }

/// Tailwind colour class for a mod asset type.
let assetTypeColour = (t: modAssetType): string =>
  switch t {
  | AssetSprite => "text-cyan-400"
  | AssetSound => "text-amber-400"
  | AssetMap => "text-emerald-400"
  | AssetTileset => "text-purple-400"
  | AssetAnimation => "text-orange-400"
  | AssetScript => "text-red-400"
  }

/// Human-readable label for an ABI validation result.
let validationStatusLabel = (result: abiValidationResult): string =>
  if result.allPassed {
    "All proofs passed"
  } else {
    `${Int.toString(Array.length(result.errors))} proof(s) failed`
  }

/// Tailwind colour class for an ABI validation result.
let validationStatusColour = (result: abiValidationResult): string =>
  if result.allPassed {
    "text-emerald-400"
  } else {
    "text-red-400"
  }

/// Human-readable label for a distribution platform.
let platformLabel = (p: distributionPlatform): string =>
  switch p {
  | PlatformGithub => "GitHub"
  | PlatformWorkshop => "Workshop"
  | PlatformLocal => "Local"
  | PlatformCustom => "Custom"
  }

/// Tailwind colour class for a distribution platform.
let platformColour = (p: distributionPlatform): string =>
  switch p {
  | PlatformGithub => "text-gray-200"
  | PlatformWorkshop => "text-cyan-400"
  | PlatformLocal => "text-amber-400"
  | PlatformCustom => "text-purple-400"
  }

/// Filter projects by text search (matches name and description).
let filterProjects = (projects: array<modProject>, filterText: string): array<modProject> => {
  if filterText === "" {
    projects
  } else {
    let lower = String.toLowerCase(filterText)
    projects->Array.filter(p =>
      String.includes(String.toLowerCase(p.name), lower) ||
      String.includes(String.toLowerCase(p.description), lower)
    )
  }
}

/// Filter templates by text search (matches name and description).
let filterTemplates = (templates: array<modTemplate>, filterText: string): array<modTemplate> => {
  if filterText === "" {
    templates
  } else {
    let lower = String.toLowerCase(filterText)
    templates->Array.filter(t =>
      String.includes(String.toLowerCase(t.name), lower) ||
      String.includes(String.toLowerCase(t.description), lower)
    )
  }
}

/// Filter assets by text search (matches name and file path).
let filterAssets = (assets: array<modAsset>, filterText: string): array<modAsset> => {
  if filterText === "" {
    assets
  } else {
    let lower = String.toLowerCase(filterText)
    assets->Array.filter(a =>
      String.includes(String.toLowerCase(a.name), lower) ||
      String.includes(String.toLowerCase(a.filePath), lower)
    )
  }
}

/// Count assets by type.
let countByAssetType = (assets: array<modAsset>, assetType: modAssetType): int =>
  assets->Array.filter(a => a.assetType === assetType)->Array.length

/// Count projects that have passed ABI validation.
let validatedProjectCount = (projects: array<modProject>): int =>
  projects->Array.filter(p => p.validated)->Array.length

/// All UMS category tabs for rendering.
let allCategories: array<umsCategory> = [
  UmsProjects,
  UmsAbiValidator,
  UmsTemplates,
  UmsAssets,
  UmsDistribution,
  UmsApiReference,
]

/// All mod asset types for filter dropdowns.
let allAssetTypes: array<modAssetType> = [
  AssetSprite,
  AssetSound,
  AssetMap,
  AssetTileset,
  AssetAnimation,
  AssetScript,
]

/// Default state for the Universal Modding Studio panel.
let defaultState: umsState = {
  activeCategory: UmsProjects,
  projects: [],
  templates: [],
  assets: [],
  selectedProjectId: None,
  validationResults: [],
  distributionTargets: [],
  apiEntries: [],
  filterText: "",
  loading: false,
  error: None,
  bojRouting: false,
}
