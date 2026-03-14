// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * UmsEngine Tests — category labels, icons, template categories, asset types,
 * validation status, platform labels, filtering, counting, and default state.
 */

import { assertEquals } from "jsr:@std/assert";
import {
  categoryLabel,
  categoryIcon,
  templateCategoryLabel,
  templateCategoryColour,
  assetTypeLabel,
  assetTypeColour,
  validationStatusLabel,
  validationStatusColour,
  platformLabel,
  platformColour,
  filterProjects,
  filterTemplates,
  filterAssets,
  countByAssetType,
  validatedProjectCount,
  allCategories,
  allAssetTypes,
  defaultState,
} from "../src/core/UmsEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns Projects for UmsProjects", () => {
  assertEquals(categoryLabel("UmsProjects"), "Projects");
});

Deno.test("categoryLabel returns ABI Validator for UmsAbiValidator", () => {
  assertEquals(categoryLabel("UmsAbiValidator"), "ABI Validator");
});

Deno.test("categoryLabel returns Templates for UmsTemplates", () => {
  assertEquals(categoryLabel("UmsTemplates"), "Templates");
});

Deno.test("categoryLabel returns Assets for UmsAssets", () => {
  assertEquals(categoryLabel("UmsAssets"), "Assets");
});

Deno.test("categoryLabel returns Distribution for UmsDistribution", () => {
  assertEquals(categoryLabel("UmsDistribution"), "Distribution");
});

Deno.test("categoryLabel returns API Reference for UmsApiReference", () => {
  assertEquals(categoryLabel("UmsApiReference"), "API Reference");
});

// -- categoryIcon --

Deno.test("categoryIcon returns [P] for UmsProjects", () => {
  assertEquals(categoryIcon("UmsProjects"), "[P]");
});

Deno.test("categoryIcon returns [V] for UmsAbiValidator", () => {
  assertEquals(categoryIcon("UmsAbiValidator"), "[V]");
});

Deno.test("categoryIcon returns [T] for UmsTemplates", () => {
  assertEquals(categoryIcon("UmsTemplates"), "[T]");
});

Deno.test("categoryIcon returns [A] for UmsAssets", () => {
  assertEquals(categoryIcon("UmsAssets"), "[A]");
});

Deno.test("categoryIcon returns [D] for UmsDistribution", () => {
  assertEquals(categoryIcon("UmsDistribution"), "[D]");
});

Deno.test("categoryIcon returns [R] for UmsApiReference", () => {
  assertEquals(categoryIcon("UmsApiReference"), "[R]");
});

// -- templateCategoryLabel --

Deno.test("templateCategoryLabel returns Level", () => {
  assertEquals(templateCategoryLabel("TemplateLevel"), "Level");
});

Deno.test("templateCategoryLabel returns Puzzle", () => {
  assertEquals(templateCategoryLabel("TemplatePuzzle"), "Puzzle");
});

Deno.test("templateCategoryLabel returns Campaign", () => {
  assertEquals(templateCategoryLabel("TemplateCampaign"), "Campaign");
});

Deno.test("templateCategoryLabel returns Asset Pack", () => {
  assertEquals(templateCategoryLabel("TemplateAssetPack"), "Asset Pack");
});

// -- templateCategoryColour --

Deno.test("templateCategoryColour returns cyan for Level", () => {
  assertEquals(templateCategoryColour("TemplateLevel"), "text-cyan-400");
});

Deno.test("templateCategoryColour returns amber for Puzzle", () => {
  assertEquals(templateCategoryColour("TemplatePuzzle"), "text-amber-400");
});

Deno.test("templateCategoryColour returns purple for Campaign", () => {
  assertEquals(templateCategoryColour("TemplateCampaign"), "text-purple-400");
});

Deno.test("templateCategoryColour returns emerald for Asset Pack", () => {
  assertEquals(templateCategoryColour("TemplateAssetPack"), "text-emerald-400");
});

// -- assetTypeLabel --

Deno.test("assetTypeLabel returns Sprite", () => {
  assertEquals(assetTypeLabel("AssetSprite"), "Sprite");
});

Deno.test("assetTypeLabel returns Sound", () => {
  assertEquals(assetTypeLabel("AssetSound"), "Sound");
});

Deno.test("assetTypeLabel returns Map", () => {
  assertEquals(assetTypeLabel("AssetMap"), "Map");
});

Deno.test("assetTypeLabel returns Tileset", () => {
  assertEquals(assetTypeLabel("AssetTileset"), "Tileset");
});

Deno.test("assetTypeLabel returns Animation", () => {
  assertEquals(assetTypeLabel("AssetAnimation"), "Animation");
});

Deno.test("assetTypeLabel returns Script", () => {
  assertEquals(assetTypeLabel("AssetScript"), "Script");
});

// -- assetTypeColour --

Deno.test("assetTypeColour returns cyan for Sprite", () => {
  assertEquals(assetTypeColour("AssetSprite"), "text-cyan-400");
});

Deno.test("assetTypeColour returns amber for Sound", () => {
  assertEquals(assetTypeColour("AssetSound"), "text-amber-400");
});

Deno.test("assetTypeColour returns emerald for Map", () => {
  assertEquals(assetTypeColour("AssetMap"), "text-emerald-400");
});

Deno.test("assetTypeColour returns purple for Tileset", () => {
  assertEquals(assetTypeColour("AssetTileset"), "text-purple-400");
});

Deno.test("assetTypeColour returns orange for Animation", () => {
  assertEquals(assetTypeColour("AssetAnimation"), "text-orange-400");
});

Deno.test("assetTypeColour returns red for Script", () => {
  assertEquals(assetTypeColour("AssetScript"), "text-red-400");
});

// -- validationStatusLabel / validationStatusColour --

Deno.test("validationStatusLabel returns all passed when allPassed is true", () => {
  const result = {
    levelId: "lvl-01",
    guardsInZones: true,
    defenceTargetsValid: true,
    zonesOrdered: true,
    pbxConsistent: true,
    devicesExist: true,
    allPassed: true,
    validatedAt: "2026-03-14T00:00:00Z",
    errors: [],
  };
  assertEquals(validationStatusLabel(result), "All proofs passed");
});

Deno.test("validationStatusLabel reports error count when allPassed is false", () => {
  const result = {
    levelId: "lvl-02",
    guardsInZones: false,
    defenceTargetsValid: true,
    zonesOrdered: true,
    pbxConsistent: true,
    devicesExist: true,
    allPassed: false,
    validatedAt: "2026-03-14T00:00:00Z",
    errors: ["guards-in-zones failed", "zone-ordering failed"],
  };
  assertEquals(validationStatusLabel(result), "2 proof(s) failed");
});

Deno.test("validationStatusColour returns emerald when all passed", () => {
  const result = {
    levelId: "lvl-01",
    guardsInZones: true,
    defenceTargetsValid: true,
    zonesOrdered: true,
    pbxConsistent: true,
    devicesExist: true,
    allPassed: true,
    validatedAt: "2026-03-14T00:00:00Z",
    errors: [],
  };
  assertEquals(validationStatusColour(result), "text-emerald-400");
});

Deno.test("validationStatusColour returns red when proofs failed", () => {
  const result = {
    levelId: "lvl-02",
    guardsInZones: false,
    defenceTargetsValid: true,
    zonesOrdered: true,
    pbxConsistent: true,
    devicesExist: true,
    allPassed: false,
    validatedAt: "2026-03-14T00:00:00Z",
    errors: ["guards-in-zones failed"],
  };
  assertEquals(validationStatusColour(result), "text-red-400");
});

// -- platformLabel --

Deno.test("platformLabel returns GitHub", () => {
  assertEquals(platformLabel("PlatformGithub"), "GitHub");
});

Deno.test("platformLabel returns Workshop", () => {
  assertEquals(platformLabel("PlatformWorkshop"), "Workshop");
});

Deno.test("platformLabel returns Local", () => {
  assertEquals(platformLabel("PlatformLocal"), "Local");
});

Deno.test("platformLabel returns Custom", () => {
  assertEquals(platformLabel("PlatformCustom"), "Custom");
});

// -- platformColour --

Deno.test("platformColour returns gray for GitHub", () => {
  assertEquals(platformColour("PlatformGithub"), "text-gray-200");
});

Deno.test("platformColour returns cyan for Workshop", () => {
  assertEquals(platformColour("PlatformWorkshop"), "text-cyan-400");
});

Deno.test("platformColour returns amber for Local", () => {
  assertEquals(platformColour("PlatformLocal"), "text-amber-400");
});

Deno.test("platformColour returns purple for Custom", () => {
  assertEquals(platformColour("PlatformCustom"), "text-purple-400");
});

// -- filterProjects --

/** Helper: build a minimal modProject record for testing. */
const makeProject = (id, name, description, validated = false) => ({
  id,
  name,
  description,
  author: "Test Author",
  version: "1.0.0",
  createdAt: "2026-01-01T00:00:00Z",
  lastModified: "2026-01-01T00:00:00Z",
  levelCount: 0,
  puzzleCount: 0,
  assetCount: 0,
  validated,
  projectPath: `/projects/${id}`,
});

const sampleProjects = [
  makeProject("p1", "Dungeon Delve", "A deep dungeon mod"),
  makeProject("p2", "Sky Tower", "Tower-climbing adventure", true),
  makeProject("p3", "Deep Forest", "Explore a mysterious forest", true),
];

Deno.test("filterProjects returns all projects when filter is empty", () => {
  assertEquals(filterProjects(sampleProjects, "").length, 3);
});

Deno.test("filterProjects matches project name case-insensitively", () => {
  const results = filterProjects(sampleProjects, "dungeon");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "p1");
});

Deno.test("filterProjects matches project description", () => {
  const results = filterProjects(sampleProjects, "tower-climbing");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "p2");
});

Deno.test("filterProjects returns empty array when nothing matches", () => {
  assertEquals(filterProjects(sampleProjects, "nonexistent").length, 0);
});

Deno.test("filterProjects matches across name and description (deep)", () => {
  const results = filterProjects(sampleProjects, "deep");
  assertEquals(results.length, 2);
});

// -- filterTemplates --

/** Helper: build a minimal modTemplate record for testing. */
const makeTemplate = (id, name, description, category) => ({
  id,
  name,
  description,
  category,
  difficulty: "Normal",
  previewImagePath: `/templates/${id}.png`,
});

const sampleTemplates = [
  makeTemplate("t1", "Basic Level", "A simple starting level", "TemplateLevel"),
  makeTemplate("t2", "Puzzle Pack", "Collection of puzzles", "TemplatePuzzle"),
  makeTemplate("t3", "Epic Campaign", "Full campaign template", "TemplateCampaign"),
];

Deno.test("filterTemplates returns all when filter is empty", () => {
  assertEquals(filterTemplates(sampleTemplates, "").length, 3);
});

Deno.test("filterTemplates matches template name", () => {
  const results = filterTemplates(sampleTemplates, "puzzle");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "t2");
});

Deno.test("filterTemplates matches template description", () => {
  const results = filterTemplates(sampleTemplates, "campaign template");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "t3");
});

// -- filterAssets --

/** Helper: build a minimal modAsset record for testing. */
const makeAsset = (id, name, assetType, filePath) => ({
  id,
  name,
  assetType,
  filePath,
  sizeBytes: 1024,
  usedIn: [],
});

const sampleAssets = [
  makeAsset("a1", "Hero Sprite", "AssetSprite", "sprites/hero.png"),
  makeAsset("a2", "Explosion Sound", "AssetSound", "sounds/boom.wav"),
  makeAsset("a3", "World Map", "AssetMap", "maps/world.json"),
  makeAsset("a4", "Walk Cycle", "AssetAnimation", "anims/walk.json"),
  makeAsset("a5", "Stone Tileset", "AssetTileset", "tiles/stone.png"),
  makeAsset("a6", "Enemy AI Script", "AssetScript", "scripts/enemy_ai.lua"),
];

Deno.test("filterAssets returns all when filter is empty", () => {
  assertEquals(filterAssets(sampleAssets, "").length, 6);
});

Deno.test("filterAssets matches asset name case-insensitively", () => {
  const results = filterAssets(sampleAssets, "hero");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "a1");
});

Deno.test("filterAssets matches file path", () => {
  const results = filterAssets(sampleAssets, "scripts/");
  assertEquals(results.length, 1);
  assertEquals(results[0].id, "a6");
});

Deno.test("filterAssets returns empty when nothing matches", () => {
  assertEquals(filterAssets(sampleAssets, "zzz_no_match").length, 0);
});

// -- countByAssetType --

Deno.test("countByAssetType counts sprites correctly", () => {
  assertEquals(countByAssetType(sampleAssets, "AssetSprite"), 1);
});

Deno.test("countByAssetType returns zero for absent type", () => {
  const spriteOnly = [makeAsset("x1", "Sprite", "AssetSprite", "s.png")];
  assertEquals(countByAssetType(spriteOnly, "AssetSound"), 0);
});

Deno.test("countByAssetType handles empty array", () => {
  assertEquals(countByAssetType([], "AssetSprite"), 0);
});

// -- validatedProjectCount --

Deno.test("validatedProjectCount counts validated projects", () => {
  assertEquals(validatedProjectCount(sampleProjects), 2);
});

Deno.test("validatedProjectCount returns zero for empty array", () => {
  assertEquals(validatedProjectCount([]), 0);
});

Deno.test("validatedProjectCount returns zero when none validated", () => {
  const unvalidated = [makeProject("u1", "Unval", "desc", false)];
  assertEquals(validatedProjectCount(unvalidated), 0);
});

// -- allCategories --

Deno.test("allCategories contains exactly 6 entries", () => {
  assertEquals(allCategories.length, 6);
});

Deno.test("allCategories first entry is UmsProjects", () => {
  assertEquals(allCategories[0], "UmsProjects");
});

Deno.test("allCategories last entry is UmsApiReference", () => {
  assertEquals(allCategories[5], "UmsApiReference");
});

// -- allAssetTypes --

Deno.test("allAssetTypes contains exactly 6 entries", () => {
  assertEquals(allAssetTypes.length, 6);
});

Deno.test("allAssetTypes first entry is AssetSprite", () => {
  assertEquals(allAssetTypes[0], "AssetSprite");
});

Deno.test("allAssetTypes last entry is AssetScript", () => {
  assertEquals(allAssetTypes[5], "AssetScript");
});

// -- defaultState --

Deno.test("defaultState activeCategory is UmsProjects", () => {
  assertEquals(defaultState.activeCategory, "UmsProjects");
});

Deno.test("defaultState projects array is empty", () => {
  assertEquals(defaultState.projects.length, 0);
});

Deno.test("defaultState templates array is empty", () => {
  assertEquals(defaultState.templates.length, 0);
});

Deno.test("defaultState assets array is empty", () => {
  assertEquals(defaultState.assets.length, 0);
});

Deno.test("defaultState selectedProjectId is undefined (None)", () => {
  assertEquals(defaultState.selectedProjectId, undefined);
});

Deno.test("defaultState filterText is empty string", () => {
  assertEquals(defaultState.filterText, "");
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});

Deno.test("defaultState bojRouting is false", () => {
  assertEquals(defaultState.bojRouting, false);
});

Deno.test("defaultState validationResults array is empty", () => {
  assertEquals(defaultState.validationResults.length, 0);
});

Deno.test("defaultState distributionTargets array is empty", () => {
  assertEquals(defaultState.distributionTargets.length, 0);
});

Deno.test("defaultState apiEntries array is empty", () => {
  assertEquals(defaultState.apiEntries.length, 0);
});
