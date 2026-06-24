// SPDX-License-Identifier: MPL-2.0

/**
 * Update integration tests
 *
 * Tests for the wired-up update loop: AntiCrash model updates,
 * OrbitalSync integration, Contractiles evaluation, and Tauri
 * command generation.
 *
 * ReScript compilation notes:
 * - Zero-arg variants compile to strings: "NoOp", "SaveState"
 * - Payload variants compile to objects: { TAG: "PaneL", _0: ... }
 * - Nested variants: { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: token } }
 */

import { assertEquals, assert } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// Helper to create a token
const makeToken = (content, confidence = 0.95) => ({
  content,
  timestamp: Date.now(),
  confidence,
  validated: false,
});

Deno.test("Update - AntiCrash ValidationPassed adds validated token to paneN", () => {
  const model = initModel();
  const initialCount = model.paneN.tokens.length;
  const token = makeToken("safe output");

  const msg = {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationPassed", _0: token },
  };

  const [newModel, _cmd] = Update.update(model, msg);
  const lastToken = newModel.paneN.tokens[newModel.paneN.tokens.length - 1];

  assertEquals(newModel.paneN.tokens.length, initialCount + 1);
  assertEquals(lastToken.content, "safe output");
  assertEquals(lastToken.validated, true);
  assertEquals(newModel.antiCrash.halted, false);
});

Deno.test("Update - AntiCrash ValidationFailed records violation", () => {
  const model = initModel();
  const initialCount = model.paneN.tokens.length;
  const token = makeToken("bad output");

  const msg = {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: token, _1: "Backend rejected" },
  };

  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneN.tokens.length, initialCount); // Token not added
  assertEquals(newModel.antiCrash.violations.length, 1);
  // strictMode is true by default, so should be halted
  assertEquals(newModel.antiCrash.halted, true);
});

Deno.test("Update - AntiCrash ValidationFailed does not halt in non-strict mode", () => {
  const model = {
    ...initModel(),
    antiCrash: {
      ...initModel().antiCrash,
      strictMode: false,
    },
  };
  const token = makeToken("questionable");

  const msg = {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: token, _1: "Rejected" },
  };

  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.antiCrash.violations.length, 1);
  assertEquals(newModel.antiCrash.halted, false); // Not strict
});

Deno.test("Update - AntiCrash RequestOperatorIntervention halts", () => {
  const model = initModel();

  const msg = {
    TAG: "AntiCrash",
    _0: { TAG: "RequestOperatorIntervention", _0: "Low confidence inference" },
  };

  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.antiCrash.halted, true);
});

Deno.test("Update - OrbitalSync runs on every update", () => {
  const model = initModel();

  // Modify paneW content to trigger a sync state change
  const msg = {
    TAG: "PaneW",
    _0: { TAG: "UpdateContent", _0: "new world content" },
  };

  const [newModel, _cmd] = Update.update(model, msg);

  // OrbitalSync should have run — syncState should be updated
  // The exact values depend on OrbitalSync implementation, but
  // we can verify the model has orbital and syncState fields
  assertEquals(typeof newModel.orbital.stability, "number");
  assertEquals(typeof newModel.orbital.divergenceLevel, "number");
  assertEquals(typeof newModel.syncState.lastWorldHash, "string");
});

Deno.test("Update - Contractiles evaluated on every update", () => {
  const model = initModel();

  // Any message should trigger contractile evaluation
  const [newModel, _cmd] = Update.update(model, "NoOp");

  // Contractiles should still be present and evaluated
  assertEquals(newModel.contractiles.length, 4);
  // Each should have a status (may be "Satisfied", "Pending", or {TAG: "Violated", _0: ...})
  for (const c of newModel.contractiles) {
    assertEquals(typeof c.id, "string");
    assertEquals(typeof c.elasticity, "number");
  }
});

Deno.test("Update - anti-inflammatory activates at high vexation", () => {
  const model = {
    ...initModel(),
    vexometer: {
      ...initModel().vexometer,
      index: 0.8, // Above 0.7 threshold
    },
  };

  // Use a real message (not NoOp) so contractile post-processing runs.
  const msg = { TAG: "View", _0: { TAG: "SetHumidity", _0: "Medium" } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.vexometer.antiInflammatoryActive, true);
});

Deno.test("Update - anti-inflammatory stays inactive at low vexation", () => {
  const model = {
    ...initModel(),
    vexometer: {
      ...initModel().vexometer,
      index: 0.3,
    },
  };

  // Use a real message (not NoOp) so contractile post-processing runs.
  const msg = { TAG: "View", _0: { TAG: "SetHumidity", _0: "Medium" } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.vexometer.antiInflammatoryActive, false);
});

Deno.test("Update - Vexometer RequestVexationIndex generates command", () => {
  const model = initModel();

  const msg = {
    TAG: "Vexometer",
    _0: "RequestVexationIndex",
  };

  const [_newModel, cmd] = Update.update(model, msg);

  // Command should be generated (not Tea_Cmd.none)
  // Tea_Cmd.none compiles to "None", a Call compiles to { TAG: "Call", _0: fn }
  // applyContractiles may wrap in Batch, so accept either Call or Batch
  assertEquals(typeof cmd, "object");
  assert(cmd.TAG === "Call" || cmd.TAG === "Batch", `Expected Call or Batch, got ${cmd.TAG}`);
});

Deno.test("Update - PaneW ImportEventChain parses input", () => {
  const model = {
    ...initModel(),
    paneW: {
      ...initModel().paneW,
      eventChainInput: JSON.stringify({
        event_chain: [
          { id: "e1", axis: "cpu", duration_ms: 100, intensity: "low", status: "pass" },
        ],
      }),
    },
  };

  const msg = {
    TAG: "PaneW",
    _0: "ImportEventChain",
  };

  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneW.eventChain.length, 1);
  assertEquals(newModel.paneW.eventChain[0].axis, "cpu");
  assertEquals(newModel.paneW.eventChainError, undefined);
});

Deno.test("Update - PaneW ClearEventChain resets event chain state", () => {
  const model = {
    ...initModel(),
    paneW: {
      ...initModel().paneW,
      eventChain: [{ id: "e1", axis: "cpu", durationMs: 100 }],
      eventChainSummary: { program: "test", weakPoints: 5 },
      eventChainTimeline: { durationMs: 1000, events: 1 },
    },
  };

  const msg = {
    TAG: "PaneW",
    _0: "ClearEventChain",
  };

  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneW.eventChain.length, 0);
  assertEquals(newModel.paneW.eventChainSummary, undefined);
  assertEquals(newModel.paneW.eventChainTimeline, undefined);
  assertEquals(newModel.paneW.eventChainError, undefined);
});
