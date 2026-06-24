// SPDX-License-Identifier: MPL-2.0

/**
 * FarmEngine Tests — priority parsing, labels, colours, categories, sort
 */

import { assertEquals, assertExists } from "jsr:@std/assert";
import {
  parsePriority,
  priorityLabel,
  priorityColour,
  categoryLabel,
  allCategories,
  sortLabel,
  allSortOptions,
} from "../src/core/FarmEngine.res.js";

// -- parsePriority --

Deno.test("parsePriority - 'high' returns High", () => {
  assertEquals(parsePriority("high"), "High");
});

Deno.test("parsePriority - 'HIGH' returns High (case-insensitive)", () => {
  assertEquals(parsePriority("HIGH"), "High");
});

Deno.test("parsePriority - 'low' returns Low", () => {
  assertEquals(parsePriority("low"), "Low");
});

Deno.test("parsePriority - unknown returns Medium", () => {
  assertEquals(parsePriority(""), "Medium");
  assertEquals(parsePriority("urgent"), "Medium");
  assertEquals(parsePriority("medium"), "Medium");
});

// -- priorityLabel --

Deno.test("priorityLabel returns correct strings", () => {
  assertEquals(priorityLabel("High"), "High");
  assertEquals(priorityLabel("Medium"), "Medium");
  assertEquals(priorityLabel("Low"), "Low");
});

// -- priorityColour --

Deno.test("priorityColour returns Tailwind classes", () => {
  assertEquals(priorityColour("High"), "text-red-400");
  assertEquals(priorityColour("Medium"), "text-amber-400");
  assertEquals(priorityColour("Low"), "text-gray-400");
});

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("AllRepos"), "All Repos");
  assertEquals(categoryLabel("ByGroup"), "By Group");
  assertEquals(categoryLabel("ByLanguage"), "By Language");
  assertEquals(categoryLabel("ByForge"), "By Forge");
  assertEquals(categoryLabel("Enrollment"), "Enrollment");
  assertEquals(categoryLabel("Health"), "Health");
});

// -- allCategories --

Deno.test("allCategories has 6 entries", () => {
  assertEquals(allCategories.length, 6);
});

// -- sortLabel --

Deno.test("sortLabel returns correct strings", () => {
  assertEquals(sortLabel("SortByName"), "Name");
  assertEquals(sortLabel("SortByPriority"), "Priority");
  assertEquals(sortLabel("SortByLanguage"), "Language");
  assertEquals(sortLabel("SortByHealth"), "Health");
});

// -- allSortOptions --

Deno.test("allSortOptions has 4 entries", () => {
  assertEquals(allSortOptions.length, 4);
});
