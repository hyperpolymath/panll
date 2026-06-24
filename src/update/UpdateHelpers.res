// SPDX-License-Identifier: MPL-2.0

/// Shared helpers for the Update engine — undo/redo snapshots, error logging,
/// and the contractiles post-processor that runs after every state transition.

open Model

// ===========================================================================
// Undo/Redo Snapshot Helpers
// ===========================================================================

/// Maximum number of entries in each undo/redo stack.
let undoStackLimit = 50

/// Serialize a lightweight snapshot of core model state to a JSON string.
/// We avoid serializing the entire model to keep snapshots small and avoid
/// circular-reference issues. Only the fields users care about undoing are
/// captured: the three panels, echidna proof input, orbital metrics, and
/// contractile statuses.
let snapshotToJson: model => string = %raw(`
  function snapshotToJson(m) {
    return JSON.stringify({
      paneL: m.paneL,
      paneN: { monologue: m.paneN.monologue, inferenceActive: m.paneN.inferenceActive },
      paneW: { content: m.paneW.content },
      echidnaProofInput: m.echidna.proofInput,
      orbital: m.orbital,
      contractiles: m.contractiles
    });
  }
`)

/// Restore a snapshot JSON string back onto the model. Fields not captured in
/// the snapshot are left untouched so transient UI state (menus, loading flags,
/// connection status, etc.) is preserved across undo/redo.
let restoreSnapshot: (model, string) => model = %raw(`
  function restoreSnapshot(m, json) {
    try {
      var s = JSON.parse(json);
      return Object.assign({}, m, {
        paneL: s.paneL != null ? s.paneL : m.paneL,
        paneN: Object.assign({}, m.paneN, s.paneN || {}),
        paneW: Object.assign({}, m.paneW, { content: s.paneW != null ? s.paneW.content : m.paneW.content }),
        echidna: Object.assign({}, m.echidna, { proofInput: s.echidnaProofInput != null ? s.echidnaProofInput : m.echidna.proofInput }),
        orbital: s.orbital != null ? s.orbital : m.orbital,
        contractiles: s.contractiles != null ? s.contractiles : m.contractiles
      });
    } catch (_e) {
      return m;
    }
  }
`)

/// Push a snapshot of the current model onto the undo stack (capped at
/// `undoStackLimit`). Returns a new model with the updated stacks — the
/// redo stack is cleared because a new action invalidates the redo history.
let pushUndoSnapshot = (model: model): model => {
  let snapshot = snapshotToJson(model)
  let stack = Array.concat(model.undoStack, [snapshot])
  // Cap at limit by dropping oldest entries.
  let trimmed = if Array.length(stack) > undoStackLimit {
    Array.slice(stack, ~start=Array.length(stack) - undoStackLimit, ~end=Array.length(stack))
  } else {
    stack
  }
  {...model, undoStack: trimmed, redoStack: []}
}

// ===========================================================================
// Error Logging
// ===========================================================================

/// Log a degraded service warning to the console. Called from Error(_) branches
/// that previously swallowed errors silently. This gives operators visibility
/// into which services are failing without disrupting the user experience.
let logDegradedService = (service: string, context: string): unit => {
  Console.warn(`[PanLL] Service degraded: ${service} — ${context}`)
}
