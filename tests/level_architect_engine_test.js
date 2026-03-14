// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * LevelArchitectEngine Tests — category labels, entity kind labels/icons,
 * defence flag labels, tool labels, entity counting, grid occupancy,
 * device/guard/dog/drone/security labels, UMS zones, UMS JSON
 * serialisation/validation, and default state validation.
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
  deviceKindLabel,
  guardRankLabel,
  dogBreedLabel,
  droneArchetypeLabel,
  securityLevelLabel,
  allDeviceKinds,
  allGuardRanks,
  allDogBreeds,
  allDroneArchetypes,
  allSecurityLevels,
  defaultUmsZones,
  toUmsJson,
  parseUmsValidation,
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

// -- deviceKindLabel --

Deno.test("deviceKindLabel returns correct strings for all 12 device kinds", () => {
  assertEquals(deviceKindLabel("DevLaptop"), "Laptop");
  assertEquals(deviceKindLabel("DevDesktop"), "Desktop");
  assertEquals(deviceKindLabel("DevServer"), "Server");
  assertEquals(deviceKindLabel("DevRouter"), "Router");
  assertEquals(deviceKindLabel("DevSwitch"), "Switch");
  assertEquals(deviceKindLabel("DevFirewall"), "Firewall");
  assertEquals(deviceKindLabel("DevCamera"), "Camera");
  assertEquals(deviceKindLabel("DevAccessPoint"), "Access Point");
  assertEquals(deviceKindLabel("DevPatchPanel"), "Patch Panel");
  assertEquals(deviceKindLabel("DevPowerSupply"), "Power Supply");
  assertEquals(deviceKindLabel("DevPhoneSystem"), "Phone System");
  assertEquals(deviceKindLabel("DevFibreHub"), "Fibre Hub");
});

// -- guardRankLabel --

Deno.test("guardRankLabel returns correct strings for all 8 guard ranks", () => {
  assertEquals(guardRankLabel("RankBasic"), "Basic");
  assertEquals(guardRankLabel("RankEnforcer"), "Enforcer");
  assertEquals(guardRankLabel("RankAntiHacker"), "Anti-Hacker");
  assertEquals(guardRankLabel("RankSentinel"), "Sentinel");
  assertEquals(guardRankLabel("RankAssassin"), "Assassin");
  assertEquals(guardRankLabel("RankElite"), "Elite");
  assertEquals(guardRankLabel("RankSecurityChief"), "Security Chief");
  assertEquals(guardRankLabel("RankRivalHacker"), "Rival Hacker");
});

// -- dogBreedLabel --

Deno.test("dogBreedLabel returns correct strings for all 3 breeds", () => {
  assertEquals(dogBreedLabel("BreedPatrol"), "Patrol");
  assertEquals(dogBreedLabel("BreedBloodhound"), "Bloodhound");
  assertEquals(dogBreedLabel("BreedRoboDog"), "RoboDog");
});

// -- droneArchetypeLabel --

Deno.test("droneArchetypeLabel returns correct strings for all 3 archetypes", () => {
  assertEquals(droneArchetypeLabel("DroneHelper"), "Helper");
  assertEquals(droneArchetypeLabel("DroneHunter"), "Hunter");
  assertEquals(droneArchetypeLabel("DroneKiller"), "Killer");
});

// -- securityLevelLabel --

Deno.test("securityLevelLabel returns correct strings for all 4 levels", () => {
  assertEquals(securityLevelLabel("SecOpen"), "Open");
  assertEquals(securityLevelLabel("SecWeak"), "Weak");
  assertEquals(securityLevelLabel("SecMedium"), "Medium");
  assertEquals(securityLevelLabel("SecStrong"), "Strong");
});

// -- allDeviceKinds --

Deno.test("allDeviceKinds has 12 entries", () => {
  assertEquals(allDeviceKinds.length, 12);
});

Deno.test("allDeviceKinds entries all have valid labels", () => {
  for (const dk of allDeviceKinds) {
    const label = deviceKindLabel(dk);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${dk}`);
  }
});

// -- allGuardRanks --

Deno.test("allGuardRanks has 8 entries", () => {
  assertEquals(allGuardRanks.length, 8);
});

Deno.test("allGuardRanks entries all have valid labels", () => {
  for (const gr of allGuardRanks) {
    const label = guardRankLabel(gr);
    assert(typeof label === "string" && label.length > 0, `Missing label for ${gr}`);
  }
});

// -- allDogBreeds --

Deno.test("allDogBreeds has 3 entries", () => {
  assertEquals(allDogBreeds.length, 3);
});

// -- allDroneArchetypes --

Deno.test("allDroneArchetypes has 3 entries", () => {
  assertEquals(allDroneArchetypes.length, 3);
});

// -- allSecurityLevels --

Deno.test("allSecurityLevels has 4 entries", () => {
  assertEquals(allSecurityLevels.length, 4);
});

Deno.test("allSecurityLevels contains expected variants", () => {
  assertEquals(allSecurityLevels, ["SecOpen", "SecWeak", "SecMedium", "SecStrong"]);
});

// -- defaultUmsZones --

Deno.test("defaultUmsZones has 3 zones", () => {
  assertEquals(defaultUmsZones.length, 3);
});

Deno.test("defaultUmsZones zone names are LAN, DMZ, SCADA", () => {
  assertEquals(defaultUmsZones[0].name, "LAN");
  assertEquals(defaultUmsZones[1].name, "DMZ");
  assertEquals(defaultUmsZones[2].name, "SCADA");
});

Deno.test("defaultUmsZones zones have ascending security tiers", () => {
  assertEquals(defaultUmsZones[0].securityTier, 1);
  assertEquals(defaultUmsZones[1].securityTier, 2);
  assertEquals(defaultUmsZones[2].securityTier, 3);
});

Deno.test("defaultUmsZones zones span contiguously from 0 to 5000", () => {
  assertEquals(defaultUmsZones[0].startX, 0.0);
  assertEquals(defaultUmsZones[0].endX, 1500.0);
  assertEquals(defaultUmsZones[1].startX, 1500.0);
  assertEquals(defaultUmsZones[1].endX, 3500.0);
  assertEquals(defaultUmsZones[2].startX, 3500.0);
  assertEquals(defaultUmsZones[2].endX, 5000.0);
});

// -- toUmsJson --

Deno.test("toUmsJson produces valid JSON from default state", () => {
  const json = toUmsJson(defaultState);
  const parsed = JSON.parse(json);
  assertEquals(parsed.levelName, "Untitled Level");
  assertEquals(parsed.gridWidth, 20);
  assertEquals(parsed.gridHeight, 15);
  assertEquals(parsed.entities.length, 0);
  assertEquals(parsed.zones.length, 3);
  assertEquals(parsed.patrols.length, 0);
  assertEquals(parsed.defenceFlags.length, 0);
});

Deno.test("toUmsJson includes entities in output", () => {
  const state = {
    ...defaultState,
    entities: [
      { id: "e1", kind: "EntityDevice", name: "Server-A", gridX: 1, gridY: 2 },
      { id: "e2", kind: "EntityGuard", name: "Guard-B", gridX: 3, gridY: 4 },
    ],
  };
  const parsed = JSON.parse(toUmsJson(state));
  assertEquals(parsed.entities.length, 2);
  assertEquals(parsed.entities[0].id, "e1");
  assertEquals(parsed.entities[0].kind, "Device");
  assertEquals(parsed.entities[1].kind, "Guard");
});

Deno.test("toUmsJson includes zones with correct fields", () => {
  const parsed = JSON.parse(toUmsJson(defaultState));
  assertEquals(parsed.zones[0].name, "LAN");
  assertEquals(parsed.zones[0].securityTier, 1);
  assertEquals(parsed.zones[2].name, "SCADA");
});

Deno.test("toUmsJson includes patrols and defence flags", () => {
  const state = {
    ...defaultState,
    patrols: [
      {
        guardId: "g1",
        waypoints: [{ x: 0, y: 0, pauseDuration: 1.0 }],
        looping: true,
        speed: 2.5,
      },
    ],
    defenceFlags: ["FlagFirewall", "FlagIDS"],
  };
  const parsed = JSON.parse(toUmsJson(state));
  assertEquals(parsed.patrols.length, 1);
  assertEquals(parsed.patrols[0].guardId, "g1");
  assertEquals(parsed.patrols[0].looping, true);
  assertEquals(parsed.patrols[0].waypoints.length, 1);
  assertEquals(parsed.defenceFlags.length, 2);
  assertEquals(parsed.defenceFlags[0], "Firewall");
  assertEquals(parsed.defenceFlags[1], "IDS/IPS");
});

// -- parseUmsValidation --

Deno.test("parseUmsValidation parses valid JSON correctly", () => {
  const input = JSON.stringify({
    guardsInZones: true,
    defenceTargetsValid: false,
    zonesOrdered: true,
    pbxConsistent: true,
    devicesExist: true,
    allPassed: false,
    proofs: [
      { name: "zone-check", passed: true, detail: "ok" },
      { name: "defence-check", passed: false, detail: "missing target" },
    ],
  });
  const result = parseUmsValidation(input);
  assert(result !== undefined, "parseUmsValidation should return Some");
  assertEquals(result.guardsInZones, true);
  assertEquals(result.defenceTargetsValid, false);
  assertEquals(result.zonesOrdered, true);
  assertEquals(result.pbxConsistent, true);
  assertEquals(result.devicesExist, true);
  assertEquals(result.allPassed, false);
  assertEquals(result.proofs.length, 2);
  assertEquals(result.proofs[0].name, "zone-check");
  assertEquals(result.proofs[0].passed, true);
  assertEquals(result.proofs[1].detail, "missing target");
});

Deno.test("parseUmsValidation returns undefined for invalid JSON", () => {
  const result = parseUmsValidation("not valid json {{{");
  assertEquals(result, undefined);
});

Deno.test("parseUmsValidation returns undefined for empty string", () => {
  const result = parseUmsValidation("");
  assertEquals(result, undefined);
});

Deno.test("parseUmsValidation defaults missing booleans to false", () => {
  const input = JSON.stringify({ proofs: [] });
  const result = parseUmsValidation(input);
  assert(result !== undefined, "parseUmsValidation should return Some for valid JSON");
  assertEquals(result.guardsInZones, false);
  assertEquals(result.defenceTargetsValid, false);
  assertEquals(result.allPassed, false);
  assertEquals(result.proofs.length, 0);
});

// -- defaultState (UMS fields) --

Deno.test("defaultState zones matches defaultUmsZones", () => {
  assertEquals(defaultState.zones.length, 3);
  assertEquals(defaultState.zones[0].name, "LAN");
  assertEquals(defaultState.zones[1].name, "DMZ");
  assertEquals(defaultState.zones[2].name, "SCADA");
});

Deno.test("defaultState umsValidation is undefined (None)", () => {
  assertEquals(defaultState.umsValidation, undefined);
});

Deno.test("defaultState bojRouting is false", () => {
  assertEquals(defaultState.bojRouting, false);
});
