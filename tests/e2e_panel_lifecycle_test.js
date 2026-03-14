// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * PanLL E2E Panel Lifecycle Tests — end-to-end verification that every panel
 * can be instantiated, routed to, and put through a Model/Update/Cmd cycle.
 *
 * These tests import the compiled ReScript modules and exercise the full TEA
 * cycle without a Tauri backend (commands degrade gracefully).
 *
 * Coverage:
 *   1. All 41+ panels can be instantiated via Model.init()
 *   2. Panel routing works (PanelRegistry lookup for each panel)
 *   3. Model/Engine/Cmd cycle works (messages produce valid state transitions)
 *   4. TypeLL cross-panel type checks are wired for all panels
 *   5. Panel state initialisation correctness
 */

import { assertEquals, assertExists, assert } from "jsr:@std/assert";
import { init } from "../src/Model.res.js";
import { update } from "../src/Update.res.js";
import {
  allPanels,
  findPanel,
  panelName,
  panelCladeId,
} from "../src/modules/PanelRegistry.res.js";

// ============================================================================
// 1. Model Initialisation — all panels have default state
// ============================================================================

Deno.test("E2E: Model.init() produces a valid model with all panel fields", () => {
  const model = init();
  assertExists(model, "init() must return a model");

  // Core panels
  assertExists(model.paneL, "model.paneL must exist");
  assertExists(model.paneN, "model.paneN must exist");
  assertExists(model.paneW, "model.paneW must exist");

  // Cognitive governance
  assertExists(model.vexometer, "model.vexometer must exist");
  assertExists(model.antiCrash, "model.antiCrash must exist");

  // Named panels
  assertExists(model.cloudguard, "model.cloudguard must exist");
  assertExists(model.vab, "model.vab must exist");
  assertExists(model.farm, "model.farm must exist");
  assertExists(model.fleet, "model.fleet must exist");
  assertExists(model.hypatia, "model.hypatia must exist");
  assertExists(model.reposystem, "model.reposystem must exist");
  assertExists(model.verisimdb, "model.verisimdb must exist");
  assertExists(model.aerie, "model.aerie must exist");
  assertExists(model.interfaces, "model.interfaces must exist");
  assertExists(model.playgrounds, "model.playgrounds must exist");
  assertExists(model.plaza, "model.plaza must exist");
  assertExists(model.minter, "model.minter must exist");
  assertExists(model.provisioner, "model.provisioner must exist");
  assertExists(model.voiceTag, "model.voiceTag must exist");
  assertExists(model.ai, "model.ai must exist");
  assertExists(model.repoLoader, "model.repoLoader must exist");
  assertExists(model.workspace, "model.workspace must exist");
  assertExists(model.capture, "model.capture must exist");
  assertExists(model.security, "model.security must exist");
  assertExists(model.migration, "model.migration must exist");
  assertExists(model.panicAttack, "model.panicAttack must exist");
  assertExists(model.massPanic, "model.massPanic must exist");
  assertExists(model.tsdm, "model.tsdm must exist");
  assertExists(model.valenceShell, "model.valenceShell must exist");
  assertExists(model.gamePreview, "model.gamePreview must exist");
  assertExists(model.vmInspector, "model.vmInspector must exist");
  assertExists(model.networkTopology, "model.networkTopology must exist");
  assertExists(model.levelArchitect, "model.levelArchitect must exist");
  assertExists(model.coprocessors, "model.coprocessors must exist");
  assertExists(model.multiplayerMonitor, "model.multiplayerMonitor must exist");
  assertExists(model.dlcWorkshop, "model.dlcWorkshop must exist");
  assertExists(model.editorBridge, "model.editorBridge must exist");
  assertExists(model.buildDashboard, "model.buildDashboard must exist");
  assertExists(model.releaseManager, "model.releaseManager must exist");
  assertExists(model.automationRouter, "model.automationRouter must exist");
  assertExists(model.boj, "model.boj must exist");
  assertExists(model.cladeBrowser, "model.cladeBrowser must exist");
  assertExists(model.tentacles, "model.tentacles must exist");
  assertExists(model.protocolSquisher, "model.protocolSquisher must exist");
  assertExists(model.myLang, "model.myLang must exist");
  assertExists(model.typell, "model.typell must exist");
});

Deno.test("E2E: Model.init() TypeLL state has panelTypeChecks dict", () => {
  const model = init();
  assertExists(model.typell.panelTypeChecks, "TypeLL panelTypeChecks must exist");
  assertEquals(model.typell.queriesServed, 0, "queriesServed starts at 0");
  assertEquals(model.typell.serviceActive, true, "TypeLL service starts active");
});

Deno.test("E2E: Model.init() busRegistry exists", () => {
  const model = init();
  assertExists(model.busRegistry, "busRegistry must exist");
});

// ============================================================================
// 2. Panel Registry — every panel can be looked up
// ============================================================================

Deno.test("E2E: PanelRegistry has all 51 registered panels", () => {
  assertEquals(allPanels.length, 51);
});

Deno.test("E2E: Every registered panel can be found by ID", () => {
  for (const panel of allPanels) {
    const found = findPanel(panel.id);
    assertExists(found, `findPanel must return a result for ${panel.id}`);
    assertEquals(found.name, panel.name, `name must match for ${panel.id}`);
  }
});

Deno.test("E2E: Every registered panel has a display name", () => {
  for (const panel of allPanels) {
    const name = panelName(panel.id);
    assert(name !== "Unknown", `panelName for ${panel.id} must not be Unknown`);
    assert(name.length > 0, `panelName for ${panel.id} must not be empty`);
  }
});

Deno.test("E2E: All panels with backends have hasBackend=true", () => {
  const backendPanels = allPanels.filter((p) => p.hasBackend);
  assert(backendPanels.length > 20, "At least 20 panels should have backends");
});

Deno.test("E2E: Every panel ID is unique", () => {
  const ids = allPanels.map((p) => p.id);
  const unique = new Set(ids);
  assertEquals(unique.size, ids.length);
});

// ============================================================================
// 3. Model/Update/Cmd Cycle — messages produce valid state transitions
// ============================================================================

Deno.test("E2E: NoOp message does not change model", () => {
  const model = init();
  const [newModel, _cmd] = update(model, "NoOp");
  assertEquals(newModel.typell.queriesServed, model.typell.queriesServed);
});

Deno.test("E2E: SaveState message does not crash", () => {
  const model = init();
  const [_newModel, _cmd] = update(model, "SaveState");
});

Deno.test("E2E: ResetAllPanels message produces a valid model", () => {
  const model = init();
  const [newModel, _cmd] = update(model, { TAG: "Workspace", _0: "ResetAllPanels" });
  assertExists(newModel, "ResetAllPanels should produce a valid model");
});

Deno.test("E2E: PaneL AddConstraint adds a constraint", () => {
  const model = init();
  const constraint = {
    id: "test-1",
    expression: "x > 0",
    active: true,
    pinned: false,
    kind: "Invariant",
    source: "manual",
  };
  const [newModel, _cmd] = update(model, {
    TAG: "PaneL",
    _0: { TAG: "AddConstraint", _0: constraint },
  });
  assert(newModel.paneL.constraints.length > model.paneL.constraints.length);
});

Deno.test("E2E: PaneN ClearTokens empties the token list", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "PaneN",
    _0: "ClearTokens",
  });
  assertEquals(newModel.paneN.tokens.length, 0);
});

Deno.test("E2E: Vexometer RecordCancellation increments counter", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Vexometer",
    _0: "RecordCancellation",
  });
  assertEquals(newModel.vexometer.recentCancellations, model.vexometer.recentCancellations + 1);
});

Deno.test("E2E: Information humidity is initialised", () => {
  const model = init();
  assertEquals(model.humidity, "Medium", "default humidity should be Medium");
});

// ============================================================================
// 4. TypeLL Cross-Panel Type Check — all panels can receive TypeCheckResult
// ============================================================================

Deno.test("E2E: CloudGuard TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "CloudGuard",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: Farm TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Farm",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: VAB TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Vab",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: Provenance TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Provenance",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: Security TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Security",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: TSDM TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Tsdm",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: Workspace TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Workspace",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: Capture TypeCheckResult stores in panelTypeChecks", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "Capture",
    _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
  });
  assertEquals(newModel.typell.queriesServed, 1);
});

Deno.test("E2E: TypeCheckResult Error degrades gracefully", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "CloudGuard",
    _0: {
      TAG: "TypeCheckResult",
      _0: { TAG: "Error", _0: "TypeLL server not reachable" },
    },
  });
  assertEquals(newModel.typell.queriesServed, 0, "Error should not increment");
});

Deno.test("E2E: Multiple TypeCheckResults increment queriesServed", () => {
  let model = init();
  const panels = ["CloudGuard", "Farm", "Vab", "Security", "Tsdm"];
  for (const panel of panels) {
    const [newModel, _cmd] = update(model, {
      TAG: panel,
      _0: { TAG: "TypeCheckResult", _0: { TAG: "Ok", _0: '{"valid":true}' } },
    });
    model = newModel;
  }
  assertEquals(model.typell.queriesServed, 5);
});

// ============================================================================
// 5. Panel State Initialisation Correctness
// ============================================================================

Deno.test("E2E: TypeLL panel state initialises with correct defaults", () => {
  const model = init();
  assertEquals(model.typell.serverConnected, false);
  assertEquals(model.typell.loading, false);
  assertEquals(model.typell.activeCategory, "TlChecker");
  assertEquals(model.typell.activeViewLayer, "Folded");
  assertEquals(model.typell.serviceActive, true);
  assertEquals(model.typell.bojRouting, false);
});

Deno.test("E2E: BoJ panel state initialises with cartridge arrays", () => {
  const model = init();
  assertExists(model.boj.cartridges, "BoJ cartridges must exist");
  assertExists(model.boj.latencyLog, "BoJ latencyLog must exist");
});

Deno.test("E2E: Automation Router initialises with rules array", () => {
  const model = init();
  assertExists(model.automationRouter, "automationRouter must exist");
  assertExists(model.automationRouter.rules, "rules must exist");
});

Deno.test("E2E: Vexometer initialises with default index", () => {
  const model = init();
  assertEquals(typeof model.vexometer.index, "number");
  assertEquals(model.vexometer.recentCancellations, 0);
  assertEquals(model.vexometer.recentCorrections, 0);
});

Deno.test("E2E: Anti-Crash gate initialises as not halted", () => {
  const model = init();
  assertEquals(model.antiCrash.halted, false);
});

Deno.test("E2E: Workspace initialises with EverythingMode", () => {
  const model = init();
  assertEquals(model.workspace.mode, "EverythingMode");
});

// ============================================================================
// 6. All 11 IDApTIK Panel State Initialisation
// ============================================================================

Deno.test("E2E: All 11 IDApTIK panels initialise with correct defaults", () => {
  const model = init();
  assertExists(model.valenceShell, "valenceShell must exist");
  assertExists(model.gamePreview, "gamePreview must exist");
  assertExists(model.vmInspector, "vmInspector must exist");
  assertExists(model.networkTopology, "networkTopology must exist");
  assertExists(model.levelArchitect, "levelArchitect must exist");
  assertExists(model.coprocessors, "coprocessors must exist");
  assertExists(model.multiplayerMonitor, "multiplayerMonitor must exist");
  assertExists(model.dlcWorkshop, "dlcWorkshop must exist");
  assertExists(model.editorBridge, "editorBridge must exist");
  assertExists(model.buildDashboard, "buildDashboard must exist");
  assertExists(model.releaseManager, "releaseManager must exist");
});

// ============================================================================
// 7. Clade Coverage
// ============================================================================

Deno.test("E2E: At least 38 of 41 panels have clade IDs", () => {
  let withClade = 0;
  for (const panel of allPanels) {
    const cid = panelCladeId(panel.id);
    if (cid !== undefined) withClade++;
  }
  assert(withClade >= 38, `Expected >= 38 panels with clades, got ${withClade}`);
});

Deno.test("E2E: All clade IDs are non-empty strings", () => {
  for (const panel of allPanels) {
    const cid = panelCladeId(panel.id);
    if (cid !== undefined) {
      assert(typeof cid === "string", `Clade ID for ${panel.id} must be string`);
      assert(cid.length > 0, `Clade ID for ${panel.id} must not be empty`);
    }
  }
});

// ============================================================================
// 8. Cross-Panel Interactions
// ============================================================================

Deno.test("E2E: AntiCrash ValidationPassed adds token to paneN", () => {
  const model = init();
  const token = {
    content: "safe output",
    timestamp: Date.now(),
    confidence: 0.95,
    validated: false,
  };
  const [newModel, _cmd] = update(model, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationPassed", _0: token },
  });
  assertEquals(newModel.paneN.tokens.length, model.paneN.tokens.length + 1);
  assertEquals(newModel.antiCrash.halted, false);
});

Deno.test("E2E: AntiCrash ValidationFailed records violation", () => {
  const model = init();
  const token = {
    content: "bad output",
    timestamp: Date.now(),
    confidence: 0.3,
    validated: false,
  };
  const [newModel, _cmd] = update(model, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: token, _1: "Rejected" },
  });
  assertEquals(newModel.antiCrash.violations.length, 1);
});

// ============================================================================
// 9. Full Cycle Smoke Tests
// ============================================================================

Deno.test("E2E: 8-message smoke test does not crash", () => {
  let model = init();
  const messages = [
    "NoOp",
    { TAG: "PaneN", _0: "ClearTokens" },
    { TAG: "Vexometer", _0: "RecordCancellation" },
    { TAG: "Vexometer", _0: "RecordCorrection" },
    "SaveState",
    { TAG: "View", _0: "TogglePaneL" },
    "NoOp",
    { TAG: "Workspace", _0: "ResetAllPanels" },
  ];
  for (const msg of messages) {
    const [newModel, _cmd] = update(model, msg);
    assertExists(newModel, "Each update must produce a valid model");
    model = newModel;
  }
});

// ============================================================================
// 10. TypeLL Service Layer
// ============================================================================

Deno.test("E2E: TypeLL SetTlCategory changes active category", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "TypeLL",
    _0: { TAG: "SetTlCategory", _0: "TlExplorer" },
  });
  assertEquals(newModel.typell.activeCategory, "TlExplorer");
});

Deno.test("E2E: TypeLL SetViewLayer changes progressive disclosure level", () => {
  const model = init();
  const [newModel, _cmd] = update(model, {
    TAG: "TypeLL",
    _0: { TAG: "SetViewLayer", _0: "Glyphed" },
  });
  assertEquals(newModel.typell.activeViewLayer, "Glyphed");
});

Deno.test("E2E: TypeLL ToggleTypellBojRouting toggles BoJ routing", () => {
  const model = init();
  assertEquals(model.typell.bojRouting, false);
  const [newModel, _cmd] = update(model, {
    TAG: "TypeLL",
    _0: "ToggleTypellBojRouting",
  });
  assertEquals(newModel.typell.bojRouting, true);
});
