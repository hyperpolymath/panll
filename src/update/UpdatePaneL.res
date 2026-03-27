// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for Pane-L (Logical Constraints).
/// Manages the set of formal constraints applied to the current inference session.
/// Handles all paneLMsg variants: add, remove, toggle, pin, edit, set active,
/// and constraint type inference results.

open Model
open Msg

/// STATE TRANSITION: Pane-L (Logical Constraints)
/// Manages the set of formal constraints applied to the current inference session.
/// Handles all 6 paneLMsg variants: add, remove, toggle, pin, edit, set active.
let updatePaneL = (model: model, msg: paneLMsg): (model, Tea_Cmd.t<msg>) => {
  // Push undo snapshot for user-initiated constraint changes.
  let model = switch msg {
  | AddConstraint(_) | RemoveConstraint(_) | ToggleConstraint(_) | PinConstraint(_) =>
    UpdateHelpers.pushUndoSnapshot(model)
  | _ => model
  }
  let paneL = model.paneL
  switch msg {
  | AddConstraint(c) => {
      let newModel = {
        ...model,
        paneL: {...paneL, constraints: Array.concat(paneL.constraints, [c])},
      }
      // When the new constraint is active, dispatch a proof obligation to ECHIDNA
      // via the Panel-N monologue so the neural layer can begin verification.
      let cmd = if c.active {
        Tea_Cmd.call(callbacks => {
          let proverLabel = switch model.echidna.selectedProver {
          | Some(p) => p
          | None => "default prover"
          }
          callbacks.enqueue(
            PaneN(
              UpdateMonologue(
                model.paneN.monologue ++
                "\n\n[DISPATCH] New proof obligation: " ++
                c.expression ++
                " \u2192 dispatching to " ++
                proverLabel ++ "...",
              ),
            ),
          )
        })
      } else {
        Tea_Cmd.none
      }
      (newModel, cmd)
    }
  | RemoveConstraint(id) => (
      {
        ...model,
        paneL: {
          ...paneL,
          constraints: Array.filter(paneL.constraints, c => c.id !== id),
        },
      },
      Tea_Cmd.none,
    )
  | ToggleConstraint(id) => {
      let newConstraints = Array.map(paneL.constraints, c =>
        c.id === id ? {...c, active: !c.active} : c
      )
      let newModel = {...model, paneL: {...paneL, constraints: newConstraints}}
      // If the toggled constraint became active, dispatch an ECHIDNA proof obligation
      // to complete the symbolic-neural feedback loop.
      let toggledConstraint = Array.find(newConstraints, c => c.id === id)
      let cmd = switch toggledConstraint {
      | Some(c) if c.active =>
        Tea_Cmd.call(callbacks => {
          let proverLabel = switch model.echidna.selectedProver {
          | Some(p) => p
          | None => "default prover"
          }
          callbacks.enqueue(
            PaneN(
              UpdateMonologue(
                model.paneN.monologue ++
                "\n\n[DISPATCH] Constraint reactivated: " ++
                c.expression ++
                " \u2192 dispatching to " ++
                proverLabel ++ "...",
              ),
            ),
          )
        })
      | _ => Tea_Cmd.none
      }
      (newModel, cmd)
    }
  | PinConstraint(id) => (
      {
        ...model,
        paneL: {
          ...paneL,
          constraints: Array.map(paneL.constraints, c =>
            c.id === id ? {...c, pinned: !c.pinned} : c
          ),
        },
      },
      Tea_Cmd.none,
    )
  | UpdateEditorContent(content) => {
      // Fire TypeLL type inference on the editor content (debounced by TEA — every keystroke
      // sends a command, but the backend handles deduplication).
      let cmd = if content !== "" {
        TypeLLService.inferConstraintType(content, result => PaneL(ConstraintTypeInferred(result)))
      } else {
        Tea_Cmd.none
      }
      ({...model, paneL: {...paneL, editorContent: content, lastInferredType: None}}, cmd)
    }
  | SetActiveConstraint(id) => ({...model, paneL: {...paneL, activeConstraintId: id}}, Tea_Cmd.none)
  | ConstraintTypeInferred(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, paneL: {...paneL, lastInferredType: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | ConstraintTypeInferred(Error(_)) => {
      UpdateHelpers.logDegradedService("TypeLL", "constraint type inference failed")
      (model, Tea_Cmd.none)
    }
  }
}
