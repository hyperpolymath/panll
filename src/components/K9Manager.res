// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

/// PanLL K9 Manager Component — self-validating K9 contractile management panel.
///
/// Displays K9 security levels (Kennel/Yard/Hunt) with colour-coded badges,
/// lists loaded contractile files with validation status, and provides
/// action buttons for loading, validating, and applying K9 layouts.
///
/// Wires to K9Cmd.res functions via the K9 message channel in the TEA loop.

open Msg
open Tea.Html

/// Render a K9 security level badge with colour coding.
/// Kennel=green (safe), Yard=amber (validated), Hunt=red (full execution).
let securityLevelBadge = (level: K9Engine.k9SecurityLevel): Tea_Vdom.t<msg> => {
  let (color, label) = switch level {
  | Kennel => ("bg-green-700 text-green-100", "Kennel")
  | Yard => ("bg-amber-700 text-amber-100", "Yard")
  | Hunt => ("bg-red-700 text-red-100", "Hunt")
  }
  span(
    list{
      Attrs.class_("px-2 py-0.5 text-xs rounded font-mono " ++ color),
      Attrs.ariaLabel("Security level: " ++ label),
    },
    list{text(label)},
  )
}

/// Render a validation status indicator for a loaded file.
let validationBadge = (entry: K9Model.k9FileEntry): Tea_Vdom.t<msg> => {
  if entry.validating {
    span(
      list{Attrs.class_("text-xs text-blue-400 animate-pulse font-mono")},
      list{text("Validating...")},
    )
  } else {
    switch entry.contractile {
    | Some(c) if c.isValid =>
      span(list{Attrs.class_("text-xs text-green-400 font-mono")}, list{text("Valid")})
    | Some(c) =>
      span(
        list{
          Attrs.class_("text-xs text-red-400 font-mono"),
          Attrs.ariaLabel("Invalid: " ++ c.errors->Array.join(", ")),
        },
        list{text("Invalid (" ++ Int.toString(Array.length(c.errors)) ++ " errors)")},
      )
    | None =>
      span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text("Not validated")})
    }
  }
}

/// Render a single loaded file row.
let renderFileEntry = (entry: K9Model.k9FileEntry): Tea_Vdom.t<msg> => {
  let levelBadge = switch entry.contractile {
  | Some(c) => securityLevelBadge(c.securityLevel)
  | None => span(list{Attrs.class_("text-xs text-gray-600")}, list{text("--")})
  }
  div(
    list{
      Attrs.class_("flex items-center gap-3 px-3 py-2 bg-gray-900 border border-gray-800 rounded"),
      Attrs.role("listitem"),
      Attrs.ariaLabel("K9 file: " ++ entry.path),
    },
    list{
      levelBadge,
      span(
        list{Attrs.class_("flex-1 text-sm text-gray-300 truncate font-mono")},
        list{text(entry.path)},
      ),
      validationBadge(entry),
      button(
        list{
          Attrs.class_("px-2 py-1 text-xs bg-gray-800 hover:bg-gray-700 text-gray-300 rounded"),
          Attrs.ariaLabel("Validate " ++ entry.path),
          Events.onClick(K9(ValidateContractile(entry.path))),
        },
        list{text("Validate")},
      ),
    },
  )
}

/// Main view function for the K9 Manager panel.
let view = (state: K9Model.k9ManagerState): Tea_Vdom.t<msg> => {
  let fileCount = Array.length(state.loadedFiles)
  let validCount =
    state.loadedFiles
    ->Array.filter(e =>
      switch e.contractile {
      | Some(c) => c.isValid
      | None => false
      }
    )
    ->Array.length

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("K9 Manager — Self-validating contractile management"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-bold text-green-300")}, list{text("K9 Manager")}),
              securityLevelBadge(state.currentLevel),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(fileCount) ++ " files, " ++ Int.toString(validCount) ++ " valid",
                  ),
                },
              ),
            },
          ),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-green-800 hover:bg-green-700 text-white rounded",
                  ),
                  Attrs.ariaLabel("Load a K9 contractile file"),
                  Events.onClick(K9(LoadContractile(""))),
                },
                list{text("Load Contractile")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-amber-800 hover:bg-amber-700 text-white rounded",
                  ),
                  Attrs.ariaLabel("Apply a K9 layout preset"),
                  Events.onClick(K9(ApplyLayout(""))),
                },
                list{text("Apply Layout")},
              ),
            },
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200",
            ),
            Attrs.role("alert"),
          },
          list{text(err)},
        )
      | None => Tea_Html.noNode
      },
      // File list
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto px-4 py-4 space-y-2"),
          Attrs.role("list"),
          Attrs.ariaLabel("Loaded K9 contractile files"),
        },
        if fileCount == 0 {
          list{
            div(
              list{Attrs.class_("text-center text-gray-500 mt-8")},
              list{
                div(list{Attrs.class_("text-sm mb-2")}, list{text("No K9 files loaded")}),
                div(
                  list{Attrs.class_("text-xs")},
                  list{text("Click \"Load Contractile\" to add a .k9.ncl file")},
                ),
              },
            ),
          }
        } else {
          state.loadedFiles->Array.map(entry => renderFileEntry(entry))->List.fromArray
        },
      ),
    },
  )
}
