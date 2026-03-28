// SPDX-License-Identifier: PMPL-1.0-or-later

/// DLC Workshop messages -- puzzle CRUD, composer, testing, asset browsing,
/// packaging, import/export for the IDApTIK DLC puzzle pack panel.

open Model

type dlcWorkshopMsg =
  /// Switch the active category tab.
  | SetWorkshopCategory(dlcWorkshopCategory)
  /// Load puzzles from the DLC directory.
  | LoadPuzzles
  /// Puzzles loaded.
  | PuzzlesLoaded(result<string, string>)
  /// Select a puzzle by ID.
  | SelectPuzzle(string)
  /// Deselect the current puzzle.
  | DeselectPuzzle
  /// Add an instruction to the composer.
  | AddInstruction
  /// Remove an instruction by index.
  | RemoveInstruction(int)
  /// Clear the composer.
  | ClearComposer
  /// Save the current puzzle.
  | SavePuzzle
  /// Puzzle saved.
  | PuzzleSaved(result<string, string>)
  /// Run tests for a specific puzzle.
  | RunPuzzleTest(string)
  /// Test result for a puzzle.
  | PuzzleTestResult(result<string, string>)
  /// Run all tests.
  | RunAllTests
  /// All tests result.
  | AllTestsResult(result<string, string>)
  /// Browse DLC assets.
  | BrowseDlcAssets
  /// Assets loaded.
  | DlcAssetsLoaded(result<string, string>)
  /// Package the DLC for distribution.
  | PackageDlc
  /// Package result.
  | PackageResult(result<string, string>)
  /// Import a puzzle from file.
  | ImportPuzzle
  /// Puzzle imported.
  | PuzzleImported(result<string, string>)
  /// Export the selected puzzle.
  | ExportPuzzle
  /// Puzzle exported.
  | PuzzleExported(result<string, string>)
  /// Set filter text.
  | SetDlcFilter(string)
  /// Set difficulty filter.
  | SetDifficultyFilter(option<puzzleDifficulty>)
  /// Dismiss the error banner.
  | DismissWorkshopError
  /// TypeLL cross-panel type check result for puzzle spec types.
  | TypeCheckResult(result<string, string>)
