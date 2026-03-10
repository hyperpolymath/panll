// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * HelpEngine Tests — default state, onboarding steps, search/filter functions,
 * glossary search, category labels, and onboarding step navigation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  defaultOnboardingSteps,
  defaultState,
  searchEntries,
  filterByCategory,
  filterByPanel,
  findEntry,
  findGlossaryTerm,
  searchGlossary,
  categoryLabel,
  nextOnboardingStep,
  prevOnboardingStep,
} from "../src/core/HelpEngine.res.js";

// -- defaultState --

Deno.test("defaultState has expected initial values", () => {
  assertEquals(defaultState.searchQuery, "");
  assertEquals(defaultState.filteredEntries.length, 0);
  assertEquals(defaultState.activeCategory, "GettingStarted");
  assertEquals(defaultState.activeEntry, undefined);
  assertEquals(defaultState.glossary.length, 0);
  assertEquals(defaultState.contextPanelId, undefined);
});

Deno.test("defaultState onboarding has expected shape", () => {
  assertEquals(defaultState.onboarding.active, false);
  assertEquals(defaultState.onboarding.currentStep, 0);
  assertEquals(defaultState.onboarding.completedOnce, false);
  assert(
    Array.isArray(defaultState.onboarding.steps),
    "onboarding steps should be an array",
  );
});

// -- defaultOnboardingSteps --

Deno.test("defaultOnboardingSteps returns 8 steps", () => {
  const steps = defaultOnboardingSteps();
  assertEquals(steps.length, 8);
});

Deno.test("defaultOnboardingSteps first step is welcome", () => {
  const steps = defaultOnboardingSteps();
  assertEquals(steps[0].id, "welcome");
  assertEquals(steps[0].title, "Welcome to PanLL");
  assertEquals(steps[0].completed, false);
  assertEquals(steps[0].targetSelector, undefined);
});

Deno.test("defaultOnboardingSteps last step is start-exploring", () => {
  const steps = defaultOnboardingSteps();
  assertEquals(steps[7].id, "start-exploring");
  assertEquals(steps[7].title, "Start Exploring");
});

Deno.test("defaultOnboardingSteps all steps start uncompleted", () => {
  const steps = defaultOnboardingSteps();
  for (const step of steps) {
    assertEquals(step.completed, false);
  }
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings for all categories", () => {
  assertEquals(categoryLabel("GettingStarted"), "Getting Started");
  assertEquals(categoryLabel("Glossary"), "Glossary");
  assertEquals(categoryLabel("PanelGuide"), "Panel Guides");
  assertEquals(categoryLabel("Shortcuts"), "Shortcuts");
  assertEquals(categoryLabel("Faq"), "FAQ");
  assertEquals(categoryLabel("Architecture"), "Architecture");
});

// -- searchEntries --

Deno.test("searchEntries returns all entries for empty query", () => {
  const entries = [
    { title: "First", body: "Body one", keywords: ["a"] },
    { title: "Second", body: "Body two", keywords: ["b"] },
  ];
  assertEquals(searchEntries("", entries).length, 2);
});

Deno.test("searchEntries filters by title match", () => {
  const entries = [
    { title: "Panel Guide", body: "desc", keywords: [] },
    { title: "Shortcuts", body: "desc", keywords: [] },
  ];
  const result = searchEntries("panel", entries);
  assertEquals(result.length, 1);
  assertEquals(result[0].title, "Panel Guide");
});

Deno.test("searchEntries filters by body match", () => {
  const entries = [
    { title: "Entry A", body: "Contains neurosymbolic information", keywords: [] },
    { title: "Entry B", body: "Something else", keywords: [] },
  ];
  const result = searchEntries("neurosymbolic", entries);
  assertEquals(result.length, 1);
  assertEquals(result[0].title, "Entry A");
});

Deno.test("searchEntries filters by keyword match", () => {
  const entries = [
    { title: "Entry A", body: "desc", keywords: ["drift", "aura"] },
    { title: "Entry B", body: "desc", keywords: ["panel"] },
  ];
  const result = searchEntries("drift", entries);
  assertEquals(result.length, 1);
  assertEquals(result[0].title, "Entry A");
});

Deno.test("searchEntries is case-insensitive", () => {
  const entries = [
    { title: "PANLL Guide", body: "desc", keywords: [] },
  ];
  assertEquals(searchEntries("panll", entries).length, 1);
  assertEquals(searchEntries("PANLL", entries).length, 1);
});

// -- filterByCategory --

Deno.test("filterByCategory returns only matching entries", () => {
  const entries = [
    { category: "GettingStarted", title: "A" },
    { category: "Shortcuts", title: "B" },
    { category: "GettingStarted", title: "C" },
  ];
  const result = filterByCategory("GettingStarted", entries);
  assertEquals(result.length, 2);
});

// -- filterByPanel --

Deno.test("filterByPanel returns all entries when panelId is undefined", () => {
  const entries = [
    { panelId: "echidna", title: "A" },
    { panelId: undefined, title: "B" },
  ];
  assertEquals(filterByPanel(undefined, entries).length, 2);
});

Deno.test("filterByPanel returns only entries matching panelId", () => {
  const entries = [
    { panelId: "echidna", title: "A" },
    { panelId: "typell", title: "B" },
    { panelId: undefined, title: "C" },
  ];
  const result = filterByPanel("echidna", entries);
  assertEquals(result.length, 1);
  assertEquals(result[0].title, "A");
});

// -- findEntry --

Deno.test("findEntry returns matching entry by id", () => {
  const entries = [
    { id: "welcome", title: "Welcome" },
    { id: "shortcuts", title: "Shortcuts" },
  ];
  const result = findEntry("shortcuts", entries);
  assertEquals(result.title, "Shortcuts");
});

Deno.test("findEntry returns undefined for missing id", () => {
  const entries = [{ id: "welcome", title: "Welcome" }];
  assertEquals(findEntry("nonexistent", entries), undefined);
});

// -- findGlossaryTerm --

Deno.test("findGlossaryTerm finds by case-insensitive match", () => {
  const glossary = [
    { term: "Binary Star", definition: "A system..." },
    { term: "Drift Aura", definition: "Visual indicator..." },
  ];
  const result = findGlossaryTerm("binary star", glossary);
  assertEquals(result.term, "Binary Star");
});

Deno.test("findGlossaryTerm returns undefined for missing term", () => {
  const glossary = [{ term: "Drift Aura", definition: "Visual..." }];
  assertEquals(findGlossaryTerm("nonexistent", glossary), undefined);
});

// -- searchGlossary --

Deno.test("searchGlossary returns all entries for empty query", () => {
  const glossary = [
    { term: "A", definition: "def a" },
    { term: "B", definition: "def b" },
  ];
  assertEquals(searchGlossary("", glossary).length, 2);
});

Deno.test("searchGlossary filters by term match", () => {
  const glossary = [
    { term: "Binary Star", definition: "System" },
    { term: "Drift Aura", definition: "Visual" },
  ];
  const result = searchGlossary("binary", glossary);
  assertEquals(result.length, 1);
  assertEquals(result[0].term, "Binary Star");
});

Deno.test("searchGlossary filters by definition match", () => {
  const glossary = [
    { term: "A", definition: "neurosymbolic computing" },
    { term: "B", definition: "something else" },
  ];
  const result = searchGlossary("neurosymbolic", glossary);
  assertEquals(result.length, 1);
  assertEquals(result[0].term, "A");
});

// -- nextOnboardingStep --

Deno.test("nextOnboardingStep increments currentStep", () => {
  const state = { active: true, currentStep: 0, steps: defaultOnboardingSteps(), completedOnce: false };
  const result = nextOnboardingStep(state);
  assertEquals(result.currentStep, 1);
  assertEquals(result.active, true);
  assertEquals(result.completedOnce, false);
});

Deno.test("nextOnboardingStep deactivates and marks complete at last step", () => {
  const steps = defaultOnboardingSteps();
  const state = { active: true, currentStep: steps.length - 1, steps, completedOnce: false };
  const result = nextOnboardingStep(state);
  assertEquals(result.active, false);
  assertEquals(result.completedOnce, true);
  assertEquals(result.currentStep, steps.length - 1);
});

// -- prevOnboardingStep --

Deno.test("prevOnboardingStep decrements currentStep", () => {
  const state = { active: true, currentStep: 3, steps: defaultOnboardingSteps(), completedOnce: false };
  const result = prevOnboardingStep(state);
  assertEquals(result.currentStep, 2);
});

Deno.test("prevOnboardingStep does not go below 0", () => {
  const state = { active: true, currentStep: 0, steps: defaultOnboardingSteps(), completedOnce: false };
  const result = prevOnboardingStep(state);
  assertEquals(result.currentStep, 0);
  assertEquals(result, state);
});
