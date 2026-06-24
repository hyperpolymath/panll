// SPDX-License-Identifier: MPL-2.0

/**
 * VoiceTagEngine Tests — tag creation, filtering, types, voice commands, summary
 */

import { assertEquals } from "jsr:@std/assert";
import {
  nextId,
  addTag,
  removeTag,
  filterByType,
  filterUnresolved,
  filterByAgent,
  tagsAtLine,
  tagsInRange,
  computeSummary,
  tagTypeLabel,
  tagTypeShort,
  isModalTag,
  methodLabel,
  parseTagType,
  parseVoiceCommand,
  tagTypeToString,
  tagTypeFromString,
  emptySummary,
  defaultState,
} from "../src/core/VoiceTagEngine.res.js";

// -- nextId --

Deno.test("nextId returns 1 for empty tags", () => {
  assertEquals(nextId([]), 1);
});

Deno.test("nextId returns max + 1", () => {
  assertEquals(nextId([{ id: 3 }, { id: 7 }, { id: 2 }]), 8);
});

// -- addTag / removeTag --

Deno.test("addTag appends tag", () => {
  const tag = { id: 1 };
  assertEquals(addTag([], tag).length, 1);
});

Deno.test("removeTag removes by id", () => {
  const tags = [{ id: 1 }, { id: 2 }];
  assertEquals(removeTag(tags, 1).length, 1);
  assertEquals(removeTag(tags, 1)[0].id, 2);
});

// -- filterByType / filterUnresolved / filterByAgent --

Deno.test("filterByType filters correctly", () => {
  const tags = [{ tagType: "Todo" }, { tagType: "Fixme" }, { tagType: "Todo" }];
  assertEquals(filterByType(tags, "Todo").length, 2);
});

Deno.test("filterUnresolved filters resolved tags", () => {
  const tags = [{ resolved: false }, { resolved: true }];
  assertEquals(filterUnresolved(tags).length, 1);
});

Deno.test("filterByAgent filters by agent", () => {
  const tags = [{ attribution: { agent: "human" } }, { attribution: { agent: "claude" } }];
  assertEquals(filterByAgent(tags, "human").length, 1);
});

// -- tagsAtLine / tagsInRange --

Deno.test("tagsAtLine returns tags covering a line", () => {
  const tags = [{ startLine: 1, endLine: 10 }, { startLine: 20, endLine: 30 }];
  assertEquals(tagsAtLine(tags, 5).length, 1);
  assertEquals(tagsAtLine(tags, 15).length, 0);
});

Deno.test("tagsInRange returns overlapping tags", () => {
  const tags = [{ startLine: 1, endLine: 10 }, { startLine: 20, endLine: 30 }];
  assertEquals(tagsInRange(tags, 5, 25).length, 2);
  assertEquals(tagsInRange(tags, 11, 19).length, 0);
});

// -- tagTypeLabel / tagTypeShort --

Deno.test("tagTypeLabel returns correct labels", () => {
  assertEquals(tagTypeLabel("Todo"), "TODO");
  assertEquals(tagTypeLabel("Fixme"), "FIXME");
  assertEquals(tagTypeLabel("CareOn"), "CARE-ON");
  assertEquals(tagTypeLabel("EcoMode"), "ECO-MODE");
  assertEquals(tagTypeLabel("Burden"), "BURDEN");
});

Deno.test("tagTypeShort returns correct abbreviations", () => {
  assertEquals(tagTypeShort("Todo"), "TD");
  assertEquals(tagTypeShort("Fixme"), "FX");
  assertEquals(tagTypeShort("CareOn"), "C!");
  assertEquals(tagTypeShort("EcoMode"), "EC");
});

// -- isModalTag --

Deno.test("isModalTag returns true for modal types", () => {
  assertEquals(isModalTag("CareOn"), true);
  assertEquals(isModalTag("EcoMode"), true);
  assertEquals(isModalTag("Burden"), true);
  assertEquals(isModalTag("Todo"), false);
  assertEquals(isModalTag("Fixme"), false);
});

// -- methodLabel --

Deno.test("methodLabel returns correct strings", () => {
  assertEquals(methodLabel("Voice"), "voice");
  assertEquals(methodLabel("Keyboard"), "keyboard");
  assertEquals(methodLabel("Api"), "api");
});

// -- parseTagType --

Deno.test("parseTagType parses known types", () => {
  assertEquals(parseTagType("todo"), "Todo");
  assertEquals(parseTagType("fixme"), "Fixme");
  assertEquals(parseTagType("care-on"), "CareOn");
  assertEquals(parseTagType("eco-mode"), "EcoMode");
  assertEquals(parseTagType("burden"), "Burden");
});

Deno.test("parseTagType returns undefined for unknown", () => {
  assertEquals(parseTagType("unknown"), undefined);
});

// -- parseVoiceCommand --

Deno.test("parseVoiceCommand parses tag selection", () => {
  const result = parseVoiceCommand("tag todo fix the thing");
  assertEquals(result.TAG, "TagSelection");
  assertEquals(result._0, "Todo");
  assertEquals(result._1, "fix the thing");
});

Deno.test("parseVoiceCommand returns unrecognised for nonsense", () => {
  const result = parseVoiceCommand("blah");
  assertEquals(result.TAG, "VoiceUnrecognised");
});

// -- tagTypeToString / tagTypeFromString --

Deno.test("tagTypeToString round-trips", () => {
  assertEquals(tagTypeToString("Todo"), "todo");
  assertEquals(tagTypeFromString("todo"), "Todo");
  assertEquals(tagTypeToString("CareOn"), "care-on");
  assertEquals(tagTypeFromString("care-on"), "CareOn");
});

// -- emptySummary --

Deno.test("emptySummary has all zeroes", () => {
  assertEquals(emptySummary.totalTags, 0);
  assertEquals(emptySummary.unresolvedTags, 0);
  assertEquals(emptySummary.todoCount, 0);
  assertEquals(emptySummary.aiTagCount, 0);
});

// -- defaultState --

Deno.test("defaultState has correct initial values", () => {
  assertEquals(defaultState.tags.length, 0);
  assertEquals(defaultState.voice, "VoiceOff");
  assertEquals(defaultState.showResolved, false);
  assertEquals(defaultState.error, undefined);
});
