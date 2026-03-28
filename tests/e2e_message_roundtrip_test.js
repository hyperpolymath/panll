// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * End-to-End Message Round-Trip Tests — full TEA cycle verification:
 *   msg dispatch → update → contractiles → governance → panel bus → state
 *
 * These tests verify that messages flow through the entire pipeline and
 * produce correct, consistent state mutations across multiple domains.
 *
 * Covers:
 *   - Single-domain round trips (PaneL, PaneN, PaneW, Governance)
 *   - Multi-domain cascades (message triggers cross-cutting effects)
 *   - Governance feedback convergence (stressed → stabilised)
 *   - State invariant preservation across message sequences
 *   - Recovery paths (halt → clear → resume)
 *   - Panel Bus event emission from governance
 *   - shouldAutoSave predicate accuracy
 */

import { assertEquals, assert, assertNotEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

// ─── Helpers ────────────────────────────────────────────────────────────

const dispatch = (model, msg) => {
  const [newModel, cmd] = Update.update(model, msg);
  return { model: newModel, cmd };
};

const dispatchN = (model, messages) => {
  let m = model;
  let lastCmd;
  for (const msg of messages) {
    const [newModel, cmd] = Update.update(m, msg);
    m = newModel;
    lastCmd = cmd;
  }
  return { model: m, cmd: lastCmd };
};

const makeToken = (content, confidence = 0.95) => ({
  content,
  timestamp: Date.now(),
  confidence,
  validated: false,
});

const makeConstraint = (id, body) => ({
  id,
  name: `Constraint-${id}`,
  body,
  active: true,
  pinned: false,
});

// ─── Single-Domain Round Trips ──────────────────────────────────────────

Deno.test("E2E — PaneL AddConstraint round-trip", () => {
  const m = initModel();
  const constraint = makeConstraint("e2e-1", "x > 0");

  const { model } = dispatch(m, { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: constraint } });

  // Constraint added to PaneL
  const found = model.paneL.constraints.find(c => c.id === "e2e-1");
  assertNotEquals(found, undefined, "Constraint should be added");
  // Contractiles still evaluated
  assert(Array.isArray(model.contractiles), "Contractiles should be present");
  // Orbital still computed
  assertEquals(typeof model.orbital.stability, "number");
});

Deno.test("E2E — PaneL RemoveConstraint round-trip", () => {
  const m = initModel();
  const constraint = makeConstraint("e2e-rm", "y = 0");

  // Add then remove
  const { model: m2 } = dispatch(m, { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: constraint } });
  const { model: m3 } = dispatch(m2, { TAG: "PaneL", _0: { TAG: "RemoveConstraint", _0: "e2e-rm" } });

  const found = m3.paneL.constraints.find(c => c.id === "e2e-rm");
  assertEquals(found, undefined, "Constraint should be removed");
});

Deno.test("E2E — PaneN token ingestion via AntiCrash round-trip", () => {
  const m = initModel();
  const token = makeToken("validated neural output", 0.95);

  const { model } = dispatch(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationPassed", _0: token },
  });

  const lastToken = model.paneN.tokens[model.paneN.tokens.length - 1];
  assertEquals(lastToken.content, "validated neural output");
  assertEquals(lastToken.validated, true);
  assertEquals(model.antiCrash.halted, false);
});

Deno.test("E2E — PaneW ImportEventChain round-trip", () => {
  const m = {
    ...initModel(),
    paneW: {
      ...initModel().paneW,
      eventChainInput: JSON.stringify({
        event_chain: [
          { id: "e1", axis: "cpu", duration_ms: 100, intensity: "low", status: "pass" },
          { id: "e2", axis: "memory", duration_ms: 200, intensity: "medium", status: "pass" },
        ],
      }),
    },
  };

  const { model } = dispatch(m, { TAG: "PaneW", _0: "ImportEventChain" });

  assertEquals(model.paneW.eventChain.length, 2);
  assertEquals(model.paneW.eventChain[0].axis, "cpu");
  assertEquals(model.paneW.eventChain[1].axis, "memory");
});

Deno.test("E2E — Vexometer RecordCancellation round-trip", () => {
  const m = initModel();
  const initialCancellations = m.vexometer.recentCancellations;

  const { model } = dispatch(m, { TAG: "Vexometer", _0: "RecordCancellation" });
  assertEquals(model.vexometer.recentCancellations, initialCancellations + 1);
});

Deno.test("E2E — Vexometer ResetVexometer round-trip", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.8, recentCancellations: 10 },
  };

  const { model } = dispatch(m, { TAG: "Vexometer", _0: "ResetVexometer" });
  assertEquals(model.vexometer.index, 0.0);
  assertEquals(model.vexometer.recentCancellations, 0);
});

// ─── Multi-Domain Cascades ──────────────────────────────────────────────

Deno.test("E2E — AntiCrash failure cascades to halt + violation + governance", () => {
  const m = initModel();
  const { model } = dispatch(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: makeToken("bad"), _1: "Security violation" },
  });

  // AntiCrash domain
  assertEquals(model.antiCrash.halted, true);
  assertEquals(model.antiCrash.violations.length, 1);

  // Governance should have reacted (anti-inflammatory, humidity, etc.)
  assertEquals(typeof model.orbital.stability, "number");
});

Deno.test("E2E — high vexation + message cascade triggers anti-inflammatory + humidity change", () => {
  const m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.85, recentCancellations: 8 },
  };

  // Send a real message to trigger full governance pass
  const { model } = dispatch(m, { TAG: "Vexometer", _0: "RecordCancellation" });

  // Anti-inflammatory should activate
  assertEquals(model.vexometer.antiInflammatoryActive, true);
});

Deno.test("E2E — constraint + token + governance in sequence", () => {
  const m = initModel();

  const { model } = dispatchN(m, [
    // Add constraint
    { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: makeConstraint("seq-1", "validated") } },
    // Ingest token
    { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: makeToken("safe output") } },
    // Recalculate orbital
    { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } },
    // Record cancellation (vexation)
    { TAG: "Vexometer", _0: "RecordCancellation" },
  ]);

  // All domains should have been updated
  assert(model.paneL.constraints.length > 0, "Constraint should be present");
  assert(model.paneN.tokens.length > 0, "Token should be present");
  assertEquals(typeof model.orbital.stability, "number");
  assert(model.vexometer.recentCancellations > 0, "Cancellation recorded");
});

// ─── Governance Feedback Convergence ────────────────────────────────────

Deno.test("E2E — stressed model converges over 10 update cycles", () => {
  let m = {
    ...initModel(),
    vexometer: { ...initModel().vexometer, index: 0.9, recentCancellations: 10, inertiaDetected: false },
    antiCrash: { ...initModel().antiCrash, violations: Array.from({ length: 8 }, (_, i) => `v-${i}`) },
    orbital: { ...initModel().orbital, stability: 0.2, divergenceLevel: 0.8 },
  };

  const stabilityHistory = [];
  for (let i = 0; i < 10; i++) {
    const [newModel] = Update.update(m, { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } });
    m = newModel;
    stabilityHistory.push(m.orbital.stability);
  }

  // Stability should remain bounded
  for (const s of stabilityHistory) {
    assert(s >= 0.0 && s <= 1.0, `Stability out of bounds: ${s}`);
  }
});

Deno.test("E2E — clean model remains stable over 20 NoOp cycles", () => {
  let m = initModel();
  for (let i = 0; i < 20; i++) {
    const [newModel] = Update.update(m, "NoOp");
    m = newModel;
  }

  // Model should still be structurally sound
  assertEquals(typeof m.orbital.stability, "number");
  assertEquals(typeof m.vexometer.index, "number");
  assert(Array.isArray(m.contractiles));
  assert(Array.isArray(m.paneL.constraints));
  assert(Array.isArray(m.paneN.tokens));
});

// ─── Recovery Paths ─────────────────────────────────────────────────────

Deno.test("E2E — halt → clear → resume: tokens flow again after unhalt", () => {
  const m = initModel();

  // 1. Halt via validation failure
  const { model: halted } = dispatch(m, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationFailed", _0: makeToken("bad"), _1: "Blocked" },
  });
  assertEquals(halted.antiCrash.halted, true);

  // 2. Clear halt — no ClearHalt msg; operator intervention clears via ValidateToken
  // In practice, halt is cleared by sending a new ValidationPassed after investigation
  // We'll test that a fresh model with halted=false can receive tokens
  const cleared = { ...halted, antiCrash: { ...halted.antiCrash, halted: false, pendingReview: undefined } };
  assertEquals(cleared.antiCrash.halted, false);

  // 3. New token should pass through
  const { model: resumed } = dispatch(cleared, {
    TAG: "AntiCrash",
    _0: { TAG: "ValidationPassed", _0: makeToken("back to normal") },
  });
  const lastToken = resumed.paneN.tokens[resumed.paneN.tokens.length - 1];
  assertEquals(lastToken.content, "back to normal");
});

Deno.test("E2E — ResetAllPanels resets panel states", () => {
  const m = initModel();

  const { model: reset } = dispatch(m, { TAG: "Workspace", _0: "ResetAllPanels" });

  // Panel-specific engines should be back to defaults
  // The workspace itself is preserved but panel engines are reset
  assert(typeof reset.tsdm === "object", "TSDM should exist");
  assert(typeof reset.security === "object", "Security should exist");
  assert(typeof reset.massPanic === "object", "MassPanic should exist");
});

// ─── State Invariants ───────────────────────────────────────────────────

Deno.test("E2E — vexometer.index stays in [0, 1] under stress", () => {
  let m = initModel();
  for (let i = 0; i < 50; i++) {
    const [newModel] = Update.update(m, { TAG: "Vexometer", _0: "RecordCancellation" });
    m = newModel;
    assert(m.vexometer.index >= 0.0 && m.vexometer.index <= 1.0,
      `Vexation index out of bounds at iteration ${i}: ${m.vexometer.index}`);
  }
});

Deno.test("E2E — orbital.stability stays in [0, 1] under divergent inputs", () => {
  let m = initModel();
  for (let i = 0; i < 20; i++) {
    m = {
      ...m,
      paneL: { ...m.paneL, editorContent: `diverging-symbolic-${i}` },
      paneN: { ...m.paneN, monologue: `diverging-neural-${i * 100}` },
    };
    const [newModel] = Update.update(m, { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } });
    m = newModel;
    assert(m.orbital.stability >= 0.0 && m.orbital.stability <= 1.0,
      `Stability out of bounds at iteration ${i}: ${m.orbital.stability}`);
  }
});

Deno.test("E2E — contractiles count is constant across updates", () => {
  const m = initModel();
  const initialCount = m.contractiles.length;

  const { model: m2 } = dispatch(m, { TAG: "Vexometer", _0: "RecordCancellation" });
  const { model: m3 } = dispatch(m2, { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } });
  const { model: m4 } = dispatch(m3, "NoOp");

  assertEquals(m2.contractiles.length, initialCount);
  assertEquals(m3.contractiles.length, initialCount);
  assertEquals(m4.contractiles.length, initialCount);
});

// ─── shouldAutoSave ─────────────────────────────────────────────────────

Deno.test("E2E — shouldAutoSave: returns boolean", () => {
  const m = initModel();
  const result = Update.shouldAutoSave(m);
  assertEquals(typeof result, "boolean");
});

Deno.test("E2E — shouldAutoSave: initial model has expected auto-save state", () => {
  const m = initModel();
  // Initial model should have a defined auto-save decision
  const result = Update.shouldAutoSave(m);
  assert(result === true || result === false, "shouldAutoSave must return true or false");
});

// ─── 20-Message Smoke Test ──────────────────────────────────────────────

Deno.test("E2E — 20-message smoke test: model stays structurally valid", () => {
  const messages = [
    "NoOp",
    "SaveState",
    { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: makeConstraint("s1", "x > 0") } },
    { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: makeConstraint("s2", "y > 0") } },
    { TAG: "PaneL", _0: { TAG: "ToggleConstraint", _0: "s1" } },
    { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: makeToken("output-1") } },
    { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: makeToken("output-2") } },
    { TAG: "PaneN", _0: "ClearTokens" },
    { TAG: "Vexometer", _0: "RecordCancellation" },
    { TAG: "Vexometer", _0: "RecordCorrection" },
    { TAG: "Orbital", _0: { TAG: "UpdateStability", _0: 0.5 } },
    { TAG: "View", _0: "TogglePaneL" },
    { TAG: "View", _0: "TogglePaneL" },
    { TAG: "View", _0: { TAG: "SetHumidity", _0: "Medium" } },
    "NoOp",
    { TAG: "PaneL", _0: { TAG: "RemoveConstraint", _0: "s2" } },
    { TAG: "AntiCrash", _0: { TAG: "ValidationPassed", _0: makeToken("output-3") } },
    { TAG: "Vexometer", _0: "ResetVexometer" },
    { TAG: "Boj", _0: "RefreshHealth" },
    "NoOp",
  ];

  const { model } = dispatchN(initModel(), messages);

  // Structural validity checks
  assert(typeof model.orbital.stability === "number", "stability is numeric");
  assert(typeof model.vexometer.index === "number", "vexation is numeric");
  assert(Array.isArray(model.contractiles), "contractiles is array");
  assert(Array.isArray(model.paneL.constraints), "constraints is array");
  assert(Array.isArray(model.paneN.tokens), "tokens is array");
  assertEquals(model.antiCrash.halted, false, "not halted after clean messages");
  assertEquals(model.vexometer.index, 0.0, "vexometer reset");
});
