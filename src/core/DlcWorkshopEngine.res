// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL DLC Workshop Engine — pure computation and helpers for the
/// IDApTIK DLC puzzle pack creation and testing panel.

open DlcWorkshopModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: dlcWorkshopCategory): string =>
  switch cat {
  | WorkshopPuzzles => "Puzzles"
  | WorkshopComposer => "Composer"
  | WorkshopTesting => "Testing"
  | WorkshopAssets => "Assets"
  | WorkshopPackaging => "Packaging"
  }

/// Human-readable difficulty labels.
let difficultyLabel = (diff: puzzleDifficulty): string =>
  switch diff {
  | DifficultyTutorial => "Tutorial"
  | DifficultyEasy => "Easy"
  | DifficultyMedium => "Medium"
  | DifficultyHard => "Hard"
  | DifficultyExpert => "Expert"
  | DifficultyNightmare => "Nightmare"
  }

/// Colour class for each difficulty.
let difficultyColour = (diff: puzzleDifficulty): string =>
  switch diff {
  | DifficultyTutorial => "text-emerald-400"
  | DifficultyEasy => "text-cyan-400"
  | DifficultyMedium => "text-amber-400"
  | DifficultyHard => "text-orange-400"
  | DifficultyExpert => "text-red-400"
  | DifficultyNightmare => "text-purple-400"
  }

/// Test status label.
let testStatusLabel = (status: testRunStatus): string =>
  switch status {
  | TestNotRun => "Not Run"
  | TestRunning => "Running..."
  | TestPassed => "Passed"
  | TestFailed(reason) => `Failed: ${reason}`
  | TestTimeout => "Timeout"
  }

/// Test status colour.
let testStatusColour = (status: testRunStatus): string =>
  switch status {
  | TestNotRun => "text-gray-500"
  | TestRunning => "text-amber-400"
  | TestPassed => "text-emerald-400"
  | TestFailed(_) => "text-red-400"
  | TestTimeout => "text-orange-400"
  }

/// All difficulty levels for filter dropdown.
let allDifficulties: array<puzzleDifficulty> = [
  DifficultyTutorial,
  DifficultyEasy,
  DifficultyMedium,
  DifficultyHard,
  DifficultyExpert,
  DifficultyNightmare,
]

/// Count puzzles by difficulty.
let countByDifficulty = (puzzles: array<dlcPuzzle>, diff: puzzleDifficulty): int =>
  puzzles->Array.filter(p => p.difficulty === diff)->Array.length

/// Count passed tests.
let passedTests = (puzzles: array<dlcPuzzle>): int =>
  puzzles->Array.filter(p => p.testStatus === TestPassed)->Array.length

/// Filter puzzles by text and difficulty.
let filterPuzzles = (
  puzzles: array<dlcPuzzle>,
  filterText: string,
  filterDifficulty: option<puzzleDifficulty>,
): array<dlcPuzzle> => {
  let filtered = switch filterDifficulty {
  | Some(diff) => puzzles->Array.filter(p => p.difficulty === diff)
  | None => puzzles
  }
  if filterText === "" {
    filtered
  } else {
    let lower = String.toLowerCase(filterText)
    filtered->Array.filter(p =>
      String.includes(String.toLowerCase(p.name), lower) ||
      String.includes(String.toLowerCase(p.description), lower)
    )
  }
}

/// Default pack metadata.
let defaultPackMeta: dlcPackMeta = {
  packId: "",
  name: "Untitled Pack",
  version: "0.1.0",
  author: "Jonathan D.A. Jewell",
  description: "",
  puzzleCount: 0,
  totalSizeBytes: 0,
}

/// Default state for the DLC Workshop panel.
let defaultState: dlcWorkshopState = {
  activeCategory: WorkshopPuzzles,
  puzzles: [],
  chains: [],
  assets: [],
  packMeta: defaultPackMeta,
  selectedPuzzleId: None,
  selectedChainId: None,
  composerInstructions: [],
  testResults: [],
  filterText: "",
  filterDifficulty: None,
  showTestOutput: false,
  loading: false,
  error: None,
}
