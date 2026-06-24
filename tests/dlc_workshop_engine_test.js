// SPDX-License-Identifier: MPL-2.0

/**
 * DlcWorkshopEngine Tests — categories, difficulties, test statuses, filtering
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  difficultyLabel,
  difficultyColour,
  testStatusLabel,
  testStatusColour,
  allDifficulties,
  countByDifficulty,
  passedTests,
  filterPuzzles,
  defaultPackMeta,
  defaultState,
} from "../src/core/DlcWorkshopEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct labels", () => {
  assertEquals(categoryLabel("WorkshopPuzzles"), "Puzzles");
  assertEquals(categoryLabel("WorkshopComposer"), "Composer");
  assertEquals(categoryLabel("WorkshopTesting"), "Testing");
  assertEquals(categoryLabel("WorkshopAssets"), "Assets");
  assertEquals(categoryLabel("WorkshopPackaging"), "Packaging");
});

// -- difficultyLabel / difficultyColour --

Deno.test("difficultyLabel returns correct labels", () => {
  assertEquals(difficultyLabel("DifficultyTutorial"), "Tutorial");
  assertEquals(difficultyLabel("DifficultyEasy"), "Easy");
  assertEquals(difficultyLabel("DifficultyHard"), "Hard");
  assertEquals(difficultyLabel("DifficultyNightmare"), "Nightmare");
});

Deno.test("difficultyColour returns correct classes", () => {
  assertEquals(difficultyColour("DifficultyTutorial"), "text-emerald-400");
  assertEquals(difficultyColour("DifficultyExpert"), "text-red-400");
  assertEquals(difficultyColour("DifficultyNightmare"), "text-purple-400");
});

// -- testStatusLabel / testStatusColour --

Deno.test("testStatusLabel returns correct strings", () => {
  assertEquals(testStatusLabel("TestNotRun"), "Not Run");
  assertEquals(testStatusLabel("TestRunning"), "Running...");
  assertEquals(testStatusLabel("TestPassed"), "Passed");
  assertEquals(testStatusLabel("TestTimeout"), "Timeout");
  assertEquals(testStatusLabel({ _0: "segfault" }), "Failed: segfault");
});

Deno.test("testStatusColour returns correct classes", () => {
  assertEquals(testStatusColour("TestNotRun"), "text-gray-500");
  assertEquals(testStatusColour("TestPassed"), "text-emerald-400");
  assertEquals(testStatusColour("TestTimeout"), "text-orange-400");
  assertEquals(testStatusColour({ _0: "x" }), "text-red-400");
});

// -- allDifficulties --

Deno.test("allDifficulties has 6 entries", () => {
  assertEquals(allDifficulties.length, 6);
});

// -- countByDifficulty --

Deno.test("countByDifficulty counts correctly", () => {
  const puzzles = [
    { difficulty: "DifficultyEasy" },
    { difficulty: "DifficultyEasy" },
    { difficulty: "DifficultyHard" },
  ];
  assertEquals(countByDifficulty(puzzles, "DifficultyEasy"), 2);
  assertEquals(countByDifficulty(puzzles, "DifficultyHard"), 1);
  assertEquals(countByDifficulty(puzzles, "DifficultyNightmare"), 0);
});

// -- passedTests --

Deno.test("passedTests counts passed puzzles", () => {
  const puzzles = [
    { testStatus: "TestPassed" },
    { testStatus: "TestNotRun" },
    { testStatus: "TestPassed" },
  ];
  assertEquals(passedTests(puzzles), 2);
});

// -- filterPuzzles --

Deno.test("filterPuzzles returns all when no filters", () => {
  const puzzles = [{ name: "a", description: "b", difficulty: "DifficultyEasy" }];
  assertEquals(filterPuzzles(puzzles, "", undefined).length, 1);
});

Deno.test("filterPuzzles filters by text", () => {
  const puzzles = [
    { name: "maze", description: "solve it", difficulty: "DifficultyEasy" },
    { name: "quiz", description: "answer", difficulty: "DifficultyEasy" },
  ];
  assertEquals(filterPuzzles(puzzles, "maze", undefined).length, 1);
});

Deno.test("filterPuzzles filters by difficulty", () => {
  const puzzles = [
    { name: "a", description: "", difficulty: "DifficultyEasy" },
    { name: "b", description: "", difficulty: "DifficultyHard" },
  ];
  assertEquals(filterPuzzles(puzzles, "", "DifficultyHard").length, 1);
});

// -- defaultPackMeta --

Deno.test("defaultPackMeta has correct defaults", () => {
  assertEquals(defaultPackMeta.name, "Untitled Pack");
  assertEquals(defaultPackMeta.version, "0.1.0");
  assertEquals(defaultPackMeta.author, "Jonathan D.A. Jewell");
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.activeCategory, "WorkshopPuzzles");
  assertEquals(defaultState.puzzles.length, 0);
  assertEquals(defaultState.filterText, "");
  assertEquals(defaultState.loading, false);
});
