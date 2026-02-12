// SPDX-License-Identifier: PMPL-1.0-or-later

/**
 * Update module tests - TEA update logic
 */

import { assertEquals } from "jsr:@std/assert";
import { init as initModel } from "../src/Model.res.js";
import * as Update from "../src/Update.res.js";

Deno.test("Update.updatePaneL - AddConstraint grows constraint array", () => {
  const model = initModel();
  const initialCount = model.paneL.constraints.length;

  const msg = { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: { id: "new", expression: "test", active: true, pinned: false } } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneL.constraints.length, initialCount + 1);
});

Deno.test("Update.updatePaneL - RemoveConstraint removes constraint", () => {
  const model = initModel();
  const withConstraint = {
    ...model,
    paneL: {
      ...model.paneL,
      constraints: [{ id: "test", expression: "type Foo", active: true, pinned: false }]
    }
  };

  const msg = { TAG: "PaneL", _0: { TAG: "RemoveConstraint", _0: "test" } };
  const [newModel, _cmd] = Update.update(withConstraint, msg);

  assertEquals(newModel.paneL.constraints.length, 0);
});

Deno.test("Update.updatePaneL - ToggleConstraint flips active flag", () => {
  const model = initModel();
  const withConstraint = {
    ...model,
    paneL: {
      ...model.paneL,
      constraints: [{ id: "test", expression: "type Foo", active: true, pinned: false }]
    }
  };

  const msg = { TAG: "PaneL", _0: { TAG: "ToggleConstraint", _0: "test" } };
  const [newModel, _cmd] = Update.update(withConstraint, msg);

  assertEquals(newModel.paneL.constraints[0].active, false);
});

Deno.test("Update.updatePaneN - ReceiveToken adds token to array", () => {
  const model = initModel();
  const initialCount = model.paneN.tokens.length;

  const token = { content: "test", confidence: 0.9, sourcePaneId: "pane-n", inferredType: "code", validated: false };
  const msg = { TAG: "PaneN", _0: { TAG: "ReceiveToken", _0: token } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneN.tokens.length, initialCount + 1);
});

Deno.test("Update.updatePaneN - ClearTokens empties token array", () => {
  const model = initModel();
  const withTokens = {
    ...model,
    paneN: {
      ...model.paneN,
      tokens: [
        { content: "a", confidence: 0.9, sourcePaneId: "pane-n", inferredType: "code", validated: false },
        { content: "b", confidence: 0.8, sourcePaneId: "pane-n", inferredType: "code", validated: false }
      ]
    }
  };

  const msg = { TAG: "PaneN", _0: { TAG: "ClearTokens" } };
  const [newModel, _cmd] = Update.update(withTokens, msg);

  assertEquals(newModel.paneN.tokens.length, 0);
});

Deno.test("Update.updateVexometer - RecordCancellation increments counter", () => {
  const model = initModel();
  const initialCount = model.vexometer.cancellations;

  const msg = { TAG: "Vexometer", _0: { TAG: "RecordCancellation" } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.vexometer.cancellations, initialCount + 1);
});

Deno.test("Update.updateVexometer - ResetVexometer resets all fields", () => {
  const model = initModel();
  const withVexation = {
    ...model,
    vexometer: {
      ...model.vexometer,
      cancellations: 5,
      corrections: 3,
      index: 0.8
    }
  };

  const msg = { TAG: "Vexometer", _0: { TAG: "ResetVexometer" } };
  const [newModel, _cmd] = Update.update(withVexation, msg);

  assertEquals(newModel.vexometer.cancellations, 0);
  assertEquals(newModel.vexometer.corrections, 0);
  assertEquals(newModel.vexometer.index, 0.0);
});

Deno.test("Update.updateView - TogglePaneL flips visibility", () => {
  const model = initModel();
  const initialVisibility = model.paneLVisible;

  const msg = { TAG: "View", _0: { TAG: "TogglePaneL" } };
  const [newModel, _cmd] = Update.update(model, msg);

  assertEquals(newModel.paneLVisible, !initialVisibility);
});

Deno.test("Update - NoOp returns model unchanged", () => {
  const model = initModel();

  const msg = { TAG: "NoOp" };
  const [newModel, cmd] = Update.update(model, msg);

  assertEquals(newModel, model);
  assertEquals(cmd.TAG, "none");
});

Deno.test("Update.shouldAutoSave - returns true for AddConstraint", () => {
  const msg = { TAG: "PaneL", _0: { TAG: "AddConstraint", _0: { id: "test", expression: "test", active: true, pinned: false } } };
  const result = Update.shouldAutoSave(msg);

  assertEquals(result, true);
});

Deno.test("Update.shouldAutoSave - returns false for NoOp", () => {
  const msg = { TAG: "NoOp" };
  const result = Update.shouldAutoSave(msg);

  assertEquals(result, false);
});
