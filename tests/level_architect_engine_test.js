// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * LevelArchitectEngine Tests — category labels, entity kind labels/icons,
 * defence flag labels, tool labels, entity counting, grid occupancy,
 * and default state validation.
 */

import { assertEquals, assert } from "jsr:@std/assert";
import {
  categoryLabel,
  entityKindLabel,
  entityKindIcon,
  defenceFlagLabel,
  allDefenceFlags,
  toolLabel,
  countByKind,
  isOccupied,
  defaultState,
} from "../src/core/LevelArchitectEngine.res.js";

// -- categoryLabel --

Deno.test("categoryLabel returns correct strings", () => {
  assertEquals(categoryLabel("ArchitectGrid"), "Grid");
  assertEquals(categoryLabel("ArchitectAssets"), "Assets");
  assertEquals(categoryLabel("ArchitectPatrols"), "Patrols");
  assertEquals(categoryLabel("ArchitectValidation"), "Validation");
});

// -- entityKindLabel --

Deno.test("entityKindLabel returns correct strings for all kinds", () => {
  assertEquals(entityKindLabel("EntityDevice"), "Device");
  assertEquals(entityKindLabel("EntityGuard"), "Guard");
  assertEquals(entityKindLabel("EntitySpawnPoint"), "Spawn Point");
  assertEquals(entityKindLabel("EntityCompanion"), "Companion");
  assertEquals(entityKindLabel("EntityCollectable"), "Collectable");
  assertEquals(entityKindLabel("EntityTrigger"), "Trigger");
  assertEquals(entityKindLabel("EntityDecoration"), "Decoration");
});

// -- entityKindIcon --

Deno.test("entityKindIcon returns Lucide icon names", () => {
  assertEquals(entityKindIcon("EntityDevice"), "monitor");
  assertEquals(entityKindIcon("EntityGuard"), "shield-alert");
  assertEquals(entityKindIcon("EntitySpawnPoint"), "map-pin");
  assertEquals(entityKindIcon("EntityCompanion"), "bot");
  assertEquals(entityKindIcon("EntityCollectable"), "gem");
  assertEquals(entityKindIcon("EntityTrigger"), "zap");
  assertEquals(entityKindIcon("EntityDecoration"), "palette");
});

// -- defenceFlagLabel --

Deno.test("defenceFlagLabel returns correct strings for all flags", () => {
  assertEquals(defenceFlagLabel("FlagFirewall"), "Firewall");
  assertEquals(defenceFlagLabel("FlagIDS"), "IDS/IPS");
  assertEquals(defenceFlagLabel("FlagEncryption"), "Encryption");
  assertEquals(defenceFlagLabel("FlagMFA"), "Multi-Factor Auth");
  assertEquals(defenceFlagLabel("FlagBackup"), "Backup");
  assertEquals(defenceFlagLabel("FlagAuditLog"), "Audit Logging");
  assertEquals(defenceFlagLabel("FlagAccessControl"), "Access Control");
  assertEquals(defenceFlagLabel("FlagPatching"), "Patching");
  assertEquals(defenceFlagLabel("FlagSegmentation"), "Network Segmentation");
  assertEquals(defenceFlagLabel("FlagIncidentResponse"), "Incident Response");
  assertEquals(defenceFlagLabel("FlagPhysicalSecurity"), "Physical Security");
});

// -- allDefenceFlags --

Deno.test("allDefenceFlags has 11 entries", () => {
  assertEquals(allDefenceFlags.length, 11);
});

Deno.test("allDefenceFlags contains every flag variant", () => {
  const expected = [
    "FlagFirewall",
    "FlagIDS",
    "FlagEncryption",
    "FlagMFA",
    "FlagBackup",
    "FlagAuditLog",
    "FlagAccessControl",
    "FlagPatching",
    "FlagSegmentation",
    "FlagIncidentResponse",
    "FlagPhysicalSecurity",
  ];
  assertEquals(allDefenceFlags, expected);
});

Deno.test("allDefenceFlags entries all have valid labels", () => {
  for (const flag of allDefenceFlags) {
    const label = defenceFlagLabel(flag);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${flag}`);
  }
});

// -- toolLabel --

Deno.test("toolLabel returns correct strings for simple tools", () => {
  assertEquals(toolLabel("ToolSelect"), "Select");
  assertEquals(toolLabel("ToolErase"), "Erase");
  assertEquals(toolLabel("ToolPatrol"), "Patrol Path");
  assertEquals(toolLabel("ToolDefenceFlag"), "Defence Flag");
});

Deno.test("toolLabel returns Place + kind label for ToolPlace", () => {
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityDevice" }), "Place Device");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityGuard" }), "Place Guard");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntitySpawnPoint" }), "Place Spawn Point");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityCompanion" }), "Place Companion");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityCollectable" }), "Place Collectable");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityTrigger" }), "Place Trigger");
  assertEquals(toolLabel({ TAG: "ToolPlace", _0: "EntityDecoration" }), "Place Decoration");
});

// -- countByKind --

Deno.test("countByKind counts matching entities", () => {
  const entities = [
    { kind: "EntityDevice", gridX: 0, gridY: 0 },
    { kind: "EntityGuard", gridX: 1, gridY: 0 },
    { kind: "EntityDevice", gridX: 2, gridY: 0 },
    { kind: "EntityDevice", gridX: 3, gridY: 0 },
  ];
  assertEquals(countByKind(entities, "EntityDevice"), 3);
  assertEquals(countByKind(entities, "EntityGuard"), 1);
});

Deno.test("countByKind returns 0 when no matches", () => {
  const entities = [
    { kind: "EntityDevice", gridX: 0, gridY: 0 },
  ];
  assertEquals(countByKind(entities, "EntityTrigger"), 0);
});

Deno.test("countByKind returns 0 for empty entities", () => {
  assertEquals(countByKind([], "EntityDevice"), 0);
});

// -- isOccupied --

Deno.test("isOccupied returns true when cell is occupied", () => {
  const entities = [
    { kind: "EntityDevice", gridX: 5, gridY: 3 },
    { kind: "EntityGuard", gridX: 2, gridY: 7 },
  ];
  assertEquals(isOccupied(entities, 5, 3), true);
  assertEquals(isOccupied(entities, 2, 7), true);
});

Deno.test("isOccupied returns false when cell is free", () => {
  const entities = [
    { kind: "EntityDevice", gridX: 5, gridY: 3 },
  ];
  assertEquals(isOccupied(entities, 0, 0), false);
  assertEquals(isOccupied(entities, 5, 4), false);
  assertEquals(isOccupied(entities, 4, 3), false);
});

Deno.test("isOccupied returns false for empty entities", () => {
  assertEquals(isOccupied([], 0, 0), false);
});

// -- defaultState --

Deno.test("defaultState activeCategory is ArchitectGrid", () => {
  assertEquals(defaultState.activeCategory, "ArchitectGrid");
});

Deno.test("defaultState levelName is Untitled Level", () => {
  assertEquals(defaultState.levelName, "Untitled Level");
});

Deno.test("defaultState gridWidth is 20 and gridHeight is 15", () => {
  assertEquals(defaultState.gridWidth, 20);
  assertEquals(defaultState.gridHeight, 15);
});

Deno.test("defaultState has empty entities", () => {
  assertEquals(defaultState.entities.length, 0);
});

Deno.test("defaultState has empty patrols", () => {
  assertEquals(defaultState.patrols.length, 0);
});

Deno.test("defaultState has empty defenceFlags", () => {
  assertEquals(defaultState.defenceFlags.length, 0);
});

Deno.test("defaultState selectedEntityId is undefined (None)", () => {
  assertEquals(defaultState.selectedEntityId, undefined);
});

Deno.test("defaultState selectedTool is ToolSelect", () => {
  assertEquals(defaultState.selectedTool, "ToolSelect");
});

Deno.test("defaultState has empty assets", () => {
  assertEquals(defaultState.assets.length, 0);
});

Deno.test("defaultState has empty validationIssues", () => {
  assertEquals(defaultState.validationIssues.length, 0);
});

Deno.test("defaultState has empty history", () => {
  assertEquals(defaultState.history.length, 0);
});

Deno.test("defaultState historyIndex is -1", () => {
  assertEquals(defaultState.historyIndex, -1);
});

Deno.test("defaultState zoomLevel is 1.0", () => {
  assertEquals(defaultState.zoomLevel, 1.0);
});

Deno.test("defaultState showGrid is true", () => {
  assertEquals(defaultState.showGrid, true);
});

Deno.test("defaultState showPatrolPaths is true", () => {
  assertEquals(defaultState.showPatrolPaths, true);
});

Deno.test("defaultState showDefenceOverlay is false", () => {
  assertEquals(defaultState.showDefenceOverlay, false);
});

Deno.test("defaultState alertThreshold is 3", () => {
  assertEquals(defaultState.alertThreshold, 3);
});

Deno.test("defaultState loading is false", () => {
  assertEquals(defaultState.loading, false);
});

Deno.test("defaultState error is undefined (None)", () => {
  assertEquals(defaultState.error, undefined);
});
