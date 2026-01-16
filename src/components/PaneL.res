// SPDX-License-Identifier: AGPL-3.0-or-later

/// Pane-L: Symbolic Mass Component
///
/// The constraint/logic editor - "The Law" that governs neural inference.
/// Implements the Tractatus view for symbolic constraints.

open Model
open Msg
open Tea.Html

/// Render a single constraint item
let renderConstraint = (constraint: constraint): Vdom.t<msg> => {
  let activeClass = constraint.active ? "border-indigo-500" : "border-gray-700"
  let pinnedIcon = constraint.pinned ? " [pinned]" : ""

  div(
    list{
      Attrs.class(`p-2 mb-2 border ${activeClass} rounded bg-gray-800/50`),
    },
    list{
      div(
        list{Attrs.class("flex items-center justify-between")},
        list{
          div(
            list{Attrs.class("font-mono text-sm text-indigo-300")},
            list{text(constraint.expression ++ pinnedIcon)},
          ),
          div(
            list{Attrs.class("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class("text-xs text-gray-500 hover:text-indigo-400"),
                  Events.onClick(PaneL(ToggleConstraint(constraint.id))),
                },
                list{text(constraint.active ? "disable" : "enable")},
              ),
              button(
                list{
                  Attrs.class("text-xs text-gray-500 hover:text-amber-400"),
                  Events.onClick(PaneL(PinConstraint(constraint.id))),
                },
                list{text(constraint.pinned ? "unpin" : "pin")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the constraint list
let renderConstraintList = (constraints: array<constraint>): Vdom.t<msg> => {
  div(
    list{Attrs.class("mb-4")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-500 mb-2")},
        list{text("ACTIVE CONSTRAINTS")},
      ),
      if Array.length(constraints) === 0 {
        div(
          list{Attrs.class("text-gray-600 text-sm italic")},
          list{text("No constraints defined")},
        )
      } else {
        div(
          list{},
          constraints->Array.map(renderConstraint)->Array.toList,
        )
      },
    },
  )
}

/// Render the constraint editor
let renderEditor = (content: string): Vdom.t<msg> => {
  div(
    list{Attrs.class("flex-1")},
    list{
      div(
        list{Attrs.class("text-xs text-gray-500 mb-2")},
        list{text("TRACTATUS EDITOR")},
      ),
      textarea(
        list{
          Attrs.class(
            "w-full h-64 bg-gray-800 border border-gray-700 rounded p-3 font-mono text-sm text-indigo-200 resize-none focus:border-indigo-500 focus:outline-none",
          ),
          Attrs.placeholder("// Define symbolic constraints...\n// e.g., type User = { name: string, age: int }"),
          Attrs.value(content),
          Events.onInput(value => PaneL(UpdateEditorContent(value))),
        },
        list{},
      ),
    },
  )
}

/// Main Pane-L view
let view = (state: paneLState): Vdom.t<msg> => {
  div(
    list{Attrs.class("h-full flex flex-col p-4 bg-gray-900")},
    list{
      // Header
      div(
        list{Attrs.class("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class("text-indigo-400 font-semibold")},
            list{text("Symbolic Mass")},
          ),
          div(
            list{Attrs.class("text-xs text-gray-600")},
            list{text("Ctrl+Shift+L")},
          ),
        },
      ),

      // Constraint list
      renderConstraintList(state.constraints),

      // Editor
      renderEditor(state.editorContent),
    },
  )
}
