// SPDX-License-Identifier: PMPL-1.0-or-later

/// Level Architect messages -- grid editing, entity placement, patrol
/// editing, defence flag toggling, asset browsing, validation, undo/redo,
/// and level file I/O for the IDApTIK visual level design tool.

open Model

type levelArchitectMsg =
  /// Switch the active category tab.
  | SetArchitectCategory(levelArchitectCategory)
  /// Click a grid cell (place/select/erase based on tool).
  | ClickGrid(int, int)
  /// Select an entity by ID.
  | SelectEntity(string)
  /// Deselect the current entity.
  | DeselectEntity
  /// Select an editor tool.
  | SelectTool(editorTool)
  /// Toggle a defence flag on/off.
  | ToggleDefenceFlag(defenceFlag)
  /// Set the alert threshold.
  | SetAlertThreshold(int)
  /// Browse game assets.
  | BrowseAssets
  /// Assets loaded.
  | AssetsLoaded(result<string, string>)
  /// Validate the current level.
  | ValidateLevel
  /// Validation result.
  | ValidationResult(result<string, string>)
  /// Load a level from file.
  | LoadLevel(string)
  /// Level loaded.
  | LevelLoaded(result<string, string>)
  /// Save the current level.
  | SaveLevel(string)
  /// Level saved.
  | LevelSaved(result<string, string>)
  /// Export as LevelConfig.res.
  | ExportLevelConfig
  /// LevelConfig exported.
  | LevelConfigExported(result<string, string>)
  /// Undo the last action.
  | UndoAction
  /// Redo the last undone action.
  | RedoAction
  /// Toggle grid line visibility.
  | ToggleGrid
  /// Toggle patrol path visibility.
  | TogglePatrolPaths
  /// Dismiss the error banner.
  | DismissArchitectError
  /// TypeLL cross-panel type check result for level data types.
  | TypeCheckResult(result<string, string>)
  /// Toggle BoJ routing for UMS validation.
  | ToggleLaBojRouting
  /// UMS ABI validation result from BoJ cartridge.
  | UmsValidationResult(result<string, string>)
