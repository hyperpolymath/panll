// SPDX-License-Identifier: MPL-2.0

/// Universal Modding Studio messages -- project CRUD, ABI validation,
/// template management, asset pipeline, mod distribution, and API reference
/// for the unified IDApTIK game content creation hub.

open Model

type umsMsg =
  /// Switch the active category tab.
  | SetUmsCategory(umsCategory)
  /// Load mod projects from disk.
  | LoadProjects
  /// Projects loaded result.
  | ProjectsLoaded(result<string, string>)
  /// Create a new mod project.
  | CreateProject(string)
  /// Project created result.
  | ProjectCreated(result<string, string>)
  /// Select a project by ID.
  | SelectProject(string)
  /// Deselect the current project.
  | DeselectProject
  /// Open an existing project.
  | OpenProject(string)
  /// Project opened result.
  | ProjectOpened(result<string, string>)
  /// Delete a project.
  | DeleteProject(string)
  /// Project deleted result.
  | ProjectDeleted(result<string, string>)
  /// Run ABI validation on all levels.
  | ValidateAll
  /// Run ABI validation on a level.
  | ValidateLevel(string)
  /// Validation result.
  | ValidationResult(result<string, string>)
  /// Load available templates.
  | LoadTemplates
  /// Templates loaded result.
  | TemplatesLoaded(result<string, string>)
  /// Instantiate a template to create a new project.
  | InstantiateTemplate(string)
  /// Template instantiated result.
  | TemplateInstantiated(result<string, string>)
  /// Load project assets.
  | LoadAssets
  /// Assets loaded result.
  | AssetsLoaded(result<string, string>)
  /// Import an asset file.
  | ImportAsset(string)
  /// Asset imported result.
  | AssetImported(result<string, string>)
  /// Publish mod to a distribution target.
  | PublishMod
  /// Publish result.
  | PublishResult(result<string, string>)
  /// Load modding API reference.
  | LoadApiReference
  /// API reference loaded result.
  | ApiReferenceLoaded(result<string, string>)
  /// Set filter text.
  | SetUmsFilter(string)
  /// Dismiss the error banner.
  | DismissUmsError
  /// Toggle BoJ routing for UMS commands.
  | ToggleUmsBojRouting
  /// TypeLL cross-panel type check result for ABI validation.
  | AbiTypeCheckResult(result<string, string>)
  /// Navigate to a related panel (Level Architect, DLC Workshop, etc.).
  | NavigateToPanel(panelId)
