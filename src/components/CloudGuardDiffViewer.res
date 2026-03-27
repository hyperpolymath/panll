// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Diff Viewer — Three-way config diff display.
///
/// Shows differences between offline (saved), live (Cloudflare), and policy
/// (Trustfile/Nickel) values for zone settings. Each diff entry displays the
/// three values side by side with colour-coded resolution indicators.
///
/// Layout:
///   +-------------+-------------+-------------+-------------+
///   | Setting     | Offline     | Live        | Policy      |
///   +-------------+-------------+-------------+-------------+
///   | ssl.mode    | full_strict | flexible    | full_strict |  <-- red: live differs
///   | min_tls     | 1.2         | 1.2         | 1.2         |  <-- green: all match
///   | brotli      | on          | off         | on          |  <-- red: live differs
///   +-------------+-------------+-------------+-------------+
///   | 2 drifts found | 0 conflicts | 12 settings match       |
///   +------------------------------------------------------------+

open Msg
open Model
open Tea.Html

// ============================================================================
// Diff entry rendering
// ============================================================================

/// CSS class for a diff value based on whether it matches the policy.
let valueClass = (value: option<string>, policyValue: option<string>): string => {
  switch (value, policyValue) {
  | (Some(v), Some(p)) =>
    if v === p {
      "text-green-400"
    } else {
      "text-red-400"
    }
  | (None, _) => "text-gray-600 italic"
  | (_, None) => "text-gray-400"
  }
}

/// Render a single diff entry row.
let renderDiffEntry = (entry: configDiffEntry): Tea_Vdom.t<msg> => {
  let offlineDisplay = switch entry.offlineValue {
  | Some(v) => v
  | None => "—"
  }
  let liveDisplay = switch entry.liveValue {
  | Some(v) => v
  | None => "—"
  }
  let policyDisplay = switch entry.policyValue {
  | Some(v) => v
  | None => "—"
  }

  // Determine if this is a drift (live != offline) or conflict (all three differ)
  let isDrift = entry.offlineValue !== entry.liveValue
  let isConflict =
    isDrift && entry.offlineValue !== entry.policyValue && entry.liveValue !== entry.policyValue

  let rowBg = if isConflict {
    " bg-red-950/20"
  } else if isDrift {
    " bg-yellow-950/20"
  } else {
    ""
  }

  div(
    list{Attrs.class_(`flex hover:bg-gray-800/30${rowBg}`)},
    list{
      // Setting ID
      div(
        list{Attrs.class_("py-1.5 px-2 text-sm text-gray-300 font-mono flex-1")},
        list{text(entry.settingId)},
      ),
      // Offline value
      div(
        list{
          Attrs.class_(
            `py-1.5 px-2 text-sm font-mono w-28 ${valueClass(
                entry.offlineValue,
                entry.policyValue,
              )}`,
          ),
        },
        list{text(offlineDisplay)},
      ),
      // Live value
      div(
        list{
          Attrs.class_(
            `py-1.5 px-2 text-sm font-mono w-28 ${valueClass(entry.liveValue, entry.policyValue)}`,
          ),
        },
        list{text(liveDisplay)},
      ),
      // Policy value
      div(
        list{Attrs.class_("py-1.5 px-2 text-sm font-mono w-28 text-gray-500")},
        list{text(policyDisplay)},
      ),
      // Status indicator
      div(
        list{Attrs.class_("py-1.5 px-2 w-20")},
        list{
          if isConflict {
            span(list{Attrs.class_("text-xs text-red-400 font-medium")}, list{text("CONFLICT")})
          } else if isDrift {
            span(list{Attrs.class_("text-xs text-yellow-400 font-medium")}, list{text("DRIFT")})
          } else {
            span(list{Attrs.class_("text-xs text-green-400")}, list{text("OK")})
          },
        },
      ),
    },
  )
}

// ============================================================================
// Table header
// ============================================================================

/// Render the diff table header as a flex row.
let renderDiffHeader = (): Tea_Vdom.t<msg> => {
  let headerCell = (label: string, extraClass: string) =>
    div(
      list{Attrs.class_(`text-left text-xs text-gray-500 font-medium py-2 px-2 ${extraClass}`)},
      list{text(label)},
    )

  div(
    list{Attrs.class_("flex border-b border-gray-800")},
    list{
      headerCell("Setting", "flex-1"),
      headerCell("Offline", "w-28"),
      headerCell("Live", "w-28"),
      headerCell("Policy", "w-28"),
      headerCell("Status", "w-20"),
    },
  )
}

// ============================================================================
// Main diff viewer
// ============================================================================

/// Render the complete diff viewer panel.
/// Shows the three-way diff table when a diff is available, or a prompt to
/// download configs first.
let view = (configDiff: option<configDiff>, _loading: bool): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("w-72 border-l border-gray-800 p-3 overflow-y-auto"),
      Attrs.role("region"),
      Attrs.ariaLabel("Configuration Diff Viewer"),
    },
    list{
      div(list{Attrs.class_("text-xs text-gray-500 mb-3 font-medium")}, list{text("CONFIG DIFF")}),
      switch configDiff {
      | None =>
        div(
          list{Attrs.class_("text-sm text-gray-600 italic")},
          list{text("Download a config first, then compare to see diffs.")},
        )
      | Some(diff) =>
        div(
          list{},
          list{
            // Summary bar
            div(
              list{Attrs.class_("flex items-center gap-3 mb-3 text-xs")},
              list{
                span(
                  list{Attrs.class_("text-yellow-400")},
                  list{text(`${Int.toString(diff.driftCount)} drifts`)},
                ),
                span(
                  list{Attrs.class_("text-red-400")},
                  list{text(`${Int.toString(diff.conflictCount)} conflicts`)},
                ),
                span(
                  list{Attrs.class_("text-gray-500")},
                  list{
                    text(
                      `${Int.toString(
                          Array.length(diff.entries) - diff.driftCount - diff.conflictCount,
                        )} OK`,
                    ),
                  },
                ),
              },
            ),
            // Diff entries (compact list for the side panel)
            div(
              list{Attrs.class_("space-y-1")},
              diff.entries
              ->Array.filter(e => e.offlineValue !== e.liveValue)
              ->Array.map(entry => {
                let liveDisplay = switch entry.liveValue {
                | Some(v) => v
                | None => "—"
                }
                let offlineDisplay = switch entry.offlineValue {
                | Some(v) => v
                | None => "—"
                }
                div(
                  list{Attrs.class_("text-xs p-2 bg-gray-800/50 rounded")},
                  list{
                    div(
                      list{Attrs.class_("font-mono text-gray-300 mb-0.5")},
                      list{text(entry.settingId)},
                    ),
                    div(
                      list{Attrs.class_("flex items-center gap-1")},
                      list{
                        span(list{Attrs.class_("text-gray-500")}, list{text(offlineDisplay)}),
                        span(list{Attrs.class_("text-gray-600")}, list{text(" -> ")}),
                        span(list{Attrs.class_("text-yellow-400")}, list{text(liveDisplay)}),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

/// Render the diff viewer as a full-width table (for modal/expanded view).
/// This is an alternative layout for when the diff is shown in the main content area.
let viewExpanded = (configDiff: option<configDiff>): Tea_Vdom.t<msg> => {
  switch configDiff {
  | None =>
    div(
      list{Attrs.class_("text-sm text-gray-600 italic px-3 py-4")},
      list{text("No config diff available. Download a config, then compare.")},
    )
  | Some(diff) =>
    div(
      list{Attrs.class_("flex-1 overflow-y-auto")},
      list{
        div(
          list{Attrs.class_("w-full text-left")},
          list{
            renderDiffHeader(),
            div(
              list{},
              diff.entries
              ->Array.map(renderDiffEntry)
              ->List.fromArray,
            ),
          },
        ),
      },
    )
  }
}
