// SPDX-License-Identifier: MPL-2.0

/// Pane-L: Symbolic Mass Component
///
/// The constraint/logic editor - "The Law" that governs neural inference.
/// Implements the Tractatus view for symbolic constraints.

open Model
open Msg
open Tea.Html

/// Render a single constraint item
let renderConstraint = (c: symbolicConstraint): Tea_Vdom.t<msg> => {
  let activeClass = c.active ? "border-indigo-500" : "border-gray-700"
  let pinnedIcon = c.pinned ? " [pinned]" : ""

  div(
    list{
      Attrs.class_(`p-2 mb-2 border ${activeClass} rounded bg-gray-800/50`),
      Attrs.role("listitem"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between")},
        list{
          div(
            list{Attrs.class_("font-mono text-sm text-indigo-300")},
            list{text(c.expression ++ pinnedIcon)},
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_("text-xs text-gray-500 hover:text-indigo-400"),
                  Events.onClick(PaneL(ToggleConstraint(c.id))),
                  Attrs.ariaPressed(c.active),
                  Attrs.ariaLabel(
                    c.active ? "Disable constraint " ++ c.id : "Enable constraint " ++ c.id,
                  ),
                },
                list{text(c.active ? "disable" : "enable")},
              ),
              button(
                list{
                  Attrs.class_("text-xs text-gray-500 hover:text-amber-400"),
                  Events.onClick(PaneL(PinConstraint(c.id))),
                  Attrs.ariaPressed(c.pinned),
                  Attrs.ariaLabel(
                    c.pinned ? "Unpin constraint " ++ c.id : "Pin constraint " ++ c.id,
                  ),
                },
                list{text(c.pinned ? "unpin" : "pin")},
              ),
              button(
                list{
                  Attrs.class_("text-xs text-gray-500 hover:text-red-400"),
                  Events.onClick(PaneL(RemoveConstraint(c.id))),
                  Attrs.ariaLabel("Remove constraint " ++ c.id),
                },
                list{text("x")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the constraint list with active count and add button
let renderConstraintList = (constraints: array<symbolicConstraint>): Tea_Vdom.t<msg> => {
  let activeCount = constraints->Array.filter(c => c.active)->Array.length
  let totalCount = Array.length(constraints)

  div(
    list{Attrs.class_("mb-4")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              div(list{Attrs.class_("text-xs text-gray-500")}, list{text("ACTIVE CONSTRAINTS")}),
              if totalCount > 0 {
                span(
                  list{
                    Attrs.class_(
                      "text-xs px-1.5 py-0.5 rounded bg-indigo-900/40 text-indigo-400 font-mono",
                    ),
                  },
                  list{text(Int.toString(activeCount) ++ "/" ++ Int.toString(totalCount))},
                )
              } else {
                noNode
              },
            },
          ),
          button(
            list{
              Attrs.class_(
                "text-xs px-2 py-0.5 bg-indigo-900/30 hover:bg-indigo-800/40 text-indigo-400 rounded border border-indigo-800/50",
              ),
              Events.onClick(
                PaneL(
                  AddConstraint({
                    id: "user-" ++ Int.toString(totalCount + 1),
                    expression: "// New constraint",
                    active: true,
                    pinned: false,
                  }),
                ),
              ),
              Attrs.ariaLabel("Add new constraint"),
            },
            list{text("+ Add")},
          ),
        },
      ),
      if totalCount === 0 {
        div(
          list{Attrs.class_("text-gray-600 text-sm italic")},
          list{text("No constraints defined")},
        )
      } else {
        div(list{Attrs.role("list")}, constraints->Array.map(renderConstraint)->List.fromArray)
      },
    },
  )
}

// ===========================================================================
// TypeLL Inferred Type Display
// ===========================================================================

/// Render the TypeLL-inferred type for the current editor expression.
/// Compact display showing type signature in monospace.
let viewInferredType = (lastInferredType: option<string>): Tea_Vdom.t<msg> => {
  switch lastInferredType {
  | None => noNode
  | Some(json) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Error(_) => noNode
    | Ok(result) =>
      let borderColour = if result.valid {
        "border-green-700 bg-green-900/20"
      } else {
        "border-red-700 bg-red-900/20"
      }
      let labelColour = if result.valid {
        "text-green-400"
      } else {
        "text-red-400"
      }
      div(
        list{Attrs.class_("mt-2 p-2 rounded border " ++ borderColour)},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-1")},
            list{
              span(
                list{Attrs.class_("text-xs font-bold uppercase tracking-wider " ++ labelColour)},
                list{text("TypeLL")},
              ),
            },
          ),
          div(
            list{Attrs.class_("text-sm text-gray-300 font-mono")},
            list{text(result.typeSignature)},
          ),
          if Array.length(result.proofObligations) > 0 {
            div(
              list{Attrs.class_("text-xs text-yellow-400 mt-1")},
              list{text("Proof obligations: " ++ Array.join(result.proofObligations, ", "))},
            )
          } else {
            noNode
          },
          if Array.length(result.linearityIssues) > 0 {
            div(
              list{Attrs.class_("text-xs text-orange-400 mt-1")},
              list{text("Linearity: " ++ Array.join(result.linearityIssues, ", "))},
            )
          } else {
            noNode
          },
        },
      )
    }
  }
}

/// Render the constraint editor
let renderEditor = (content: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1")},
    list{
      div(list{Attrs.class_("text-xs text-gray-500 mb-2")}, list{text("TRACTATUS EDITOR")}),
      textarea(
        list{
          Attrs.class_(
            "w-full h-64 bg-gray-800 border border-gray-700 rounded p-3 font-mono text-sm text-indigo-200 resize-none focus:border-indigo-500 focus:outline-none",
          ),
          Attrs.placeholder(
            "// Define symbolic constraints...\n// e.g., type User = { name: string, age: int }",
          ),
          Attrs.value(content),
          Events.onInput(value => PaneL(UpdateEditorContent(value))),
          Attrs.ariaLabel("Tractatus Editor"),
        },
        list{},
      ),
    },
  )
}

/// Render proof obligations from a VCL-total query result certificate.
/// Displays proof type, contract, verification status, and hash for each
/// obligation the type checker inferred during query execution.
let renderProofObligations = (proofs: array<proofObligation>): Tea_Vdom.t<msg> => {
  if Array.length(proofs) === 0 {
    text("")
  } else {
    let rows =
      proofs
      ->Array.map(p => {
        let statusColour = switch p.status {
        | "verified" => "text-emerald-300"
        | "failed" => "text-red-400"
        | _ => "text-amber-300"
        }

        let hashTruncated =
          String.length(p.proofHash) > 16
            ? String.slice(p.proofHash, ~start=0, ~end=16) ++ "..."
            : p.proofHash

        div(
          list{
            Attrs.class_(
              "flex items-center justify-between text-xs border-b border-gray-800/60 py-1",
            ),
          },
          list{
            div(
              list{Attrs.class_("text-indigo-300 font-mono")},
              list{text(String.toUpperCase(p.proofType))},
            ),
            div(list{Attrs.class_("text-gray-400")}, list{text(p.contractName)}),
            div(list{Attrs.class_(statusColour ++ " font-semibold")}, list{text(p.status)}),
            div(
              list{Attrs.class_("text-gray-600 font-mono text-[10px]")},
              list{text(hashTruncated)},
            ),
          },
        )
      })
      ->List.fromArray

    div(
      list{Attrs.class_("mt-4 p-3 border border-indigo-900/30 rounded bg-indigo-900/20 space-y-2")},
      list{
        div(
          list{Attrs.class_("text-xs text-indigo-400 tracking-widest uppercase")},
          list{text("PROOF OBLIGATIONS (VCL-total)")},
        ),
        div(
          list{Attrs.class_("text-[10px] text-gray-500")},
          list{text(Int.toString(Array.length(proofs)) ++ " proof(s) from last VCL-total query")},
        ),
        div(list{Attrs.class_("space-y-0.5")}, rows),
      },
    )
  }
}

/// Render the symbolic mass density bar — shows how much constraint
/// content is feeding into the barycentre calculation.
let renderMassDensityBar = (
  constraints: array<symbolicConstraint>,
  editorContent: string,
): Tea_Vdom.t<msg> => {
  let activeConstraints = constraints->Array.filter(c => c.active)->Array.length
  let tokenCount =
    String.split(editorContent, " ")
    ->Array.filter(t => String.length(String.trim(t)) > 0)
    ->Array.length
  let mass = Math.min(1.0, Int.toFloat(tokenCount) /. 500.0)
  let massPercent = Int.toString(Int.fromFloat(mass *. 100.0))
  let barWidth = massPercent ++ "%"
  let barColour = if mass > 0.5 {
    "bg-indigo-500"
  } else if mass > 0.2 {
    "bg-indigo-600"
  } else {
    "bg-indigo-800"
  }

  div(
    list{Attrs.class_("mb-4 p-2 rounded bg-gray-800/50 border border-gray-700/50")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          div(list{Attrs.class_("text-xs text-gray-500")}, list{text("MASS DENSITY")}),
          div(
            list{Attrs.class_("text-xs font-mono text-indigo-400")},
            list{
              text(
                massPercent ++
                "% (" ++
                Int.toString(tokenCount) ++
                " tokens, " ++
                Int.toString(activeConstraints) ++ " active)",
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("w-full h-1.5 bg-gray-700 rounded-full overflow-hidden")},
        list{
          div(
            list{
              Attrs.class_(`h-full ${barColour} rounded-full transition-all`),
              Attrs.style("width", barWidth),
            },
            list{},
          ),
        },
      ),
    },
  )
}

/// Main Pane-L view
let view = (state: paneLState, proofs: array<proofObligation>): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("h-full flex flex-col p-4 bg-gray-900"),
      Attrs.role("region"),
      Attrs.ariaLabel("Symbolic Mass Panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          div(list{Attrs.class_("text-indigo-400 font-semibold")}, list{text("Symbolic Mass")}),
          div(list{Attrs.class_("text-xs text-gray-600")}, list{text("Ctrl+Shift+L")}),
        },
      ),
      // Mass density indicator
      renderMassDensityBar(state.constraints, state.editorContent),
      // Constraint list
      renderConstraintList(state.constraints),
      // Proof obligations from VCL-total queries
      renderProofObligations(proofs),
      // Editor
      renderEditor(state.editorContent),
      // TypeLL inferred type for editor expression
      viewInferredType(state.lastInferredType),
    },
  )
}
