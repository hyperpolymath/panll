// SPDX-License-Identifier: PMPL-1.0-or-later

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
                },
                list{text(c.active ? "disable" : "enable")},
              ),
              button(
                list{
                  Attrs.class_("text-xs text-gray-500 hover:text-amber-400"),
                  Events.onClick(PaneL(PinConstraint(c.id))),
                },
                list{text(c.pinned ? "unpin" : "pin")},
              ),
            },
          ),
        },
      ),
    },
  )
}

/// Render the constraint list
let renderConstraintList = (constraints: array<symbolicConstraint>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mb-4")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2")},
        list{text("ACTIVE CONSTRAINTS")},
      ),
      if Array.length(constraints) === 0 {
        div(
          list{Attrs.class_("text-gray-600 text-sm italic")},
          list{text("No constraints defined")},
        )
      } else {
        div(
          list{},
          constraints->Array.map(renderConstraint)->List.fromArray,
        )
      },
    },
  )
}

/// Render the constraint editor
let renderEditor = (content: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex-1")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2")},
        list{text("TRACTATUS EDITOR")},
      ),
      textarea(
        list{
          Attrs.class_(
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
let view = (state: paneLState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("h-full flex flex-col p-4 bg-gray-900")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class_("text-indigo-400 font-semibold")},
            list{text("Symbolic Mass")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600")},
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
