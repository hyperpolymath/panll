// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL DLC Workshop Model — types for creating, testing, and packaging
/// IDApTIK DLC puzzle packs. VM instruction composer, solution test
/// runner, difficulty classification, and asset bundling.

/// Puzzle difficulty classification.
type puzzleDifficulty =
  | DifficultyTutorial
  | DifficultyEasy
  | DifficultyMedium
  | DifficultyHard
  | DifficultyExpert
  | DifficultyNightmare

/// Test run status for a puzzle solution.
type testRunStatus =
  | TestNotRun
  | TestRunning
  | TestPassed
  | TestFailed(string)
  | TestTimeout

/// A VM instruction in the puzzle composer.
type puzzleInstruction = {
  index: int,
  opcode: string,
  operand: option<int>,
  comment: string,
}

/// A puzzle in the DLC pack.
type dlcPuzzle = {
  id: string,
  name: string,
  description: string,
  difficulty: puzzleDifficulty,
  instructions: array<puzzleInstruction>,
  solutionSteps: int,
  optimalSteps: int,
  testStatus: testRunStatus,
  hints: array<string>,
}

/// A chain of puzzles (level progression).
type puzzleChain = {
  id: string,
  name: string,
  puzzleIds: array<string>,
  unlockCondition: string,
}

/// A DLC asset (sprite, sound, etc.).
type dlcAsset = {
  id: string,
  name: string,
  assetType: string,
  filePath: string,
  sizeBytes: int,
}

/// DLC pack metadata.
type dlcPackMeta = {
  packId: string,
  name: string,
  version: string,
  author: string,
  description: string,
  puzzleCount: int,
  totalSizeBytes: int,
}

/// Category tabs for the DLC Workshop panel.
type dlcWorkshopCategory =
  | WorkshopPuzzles
  | WorkshopComposer
  | WorkshopTesting
  | WorkshopAssets
  | WorkshopPackaging

/// Root state for the DLC Workshop panel.
type dlcWorkshopState = {
  activeCategory: dlcWorkshopCategory,
  puzzles: array<dlcPuzzle>,
  chains: array<puzzleChain>,
  assets: array<dlcAsset>,
  packMeta: dlcPackMeta,
  selectedPuzzleId: option<string>,
  selectedChainId: option<string>,
  composerInstructions: array<puzzleInstruction>,
  testResults: array<(string, testRunStatus)>,
  filterText: string,
  filterDifficulty: option<puzzleDifficulty>,
  showTestOutput: bool,
  loading: bool,
  error: option<string>,
}
