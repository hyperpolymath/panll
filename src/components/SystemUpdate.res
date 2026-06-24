// SPDX-License-Identifier: MPL-2.0

/// PanLL System Update Component — system component update management panel.
///
/// Renders a three-section view:
///   1. Summary bar: total components, up-to-date, updates available, failed
///   2. Component table: grouped by category with version info and status badges
///   3. Action bar: Check All, Update All, asdf Details, Logs
///
/// Data flows through SystemUpdateCmd → Gossamer backend → shell commands
/// for rpm-ostree, flatpak, asdf, cargo, deno, fwupd.

open Model
open Msg
open Tea.Html

// ---------------------------------------------------------------------------
// Summary bar
// ---------------------------------------------------------------------------

/// Render a single metric card in the summary bar.
let renderMetricCard = (label: string, value: int, color: string): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col items-center p-3 rounded-lg bg-gray-900/60 min-w-[100px]"),
      Attrs.role("status"),
      Attrs.ariaLabel(`${label}: ${Int.toString(value)}`),
    },
    list{
      span(
        list{Attrs.class_(`text-2xl font-bold ${color}`)},
        list{text(Int.toString(value))},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-400 mt-1")},
        list{text(label)},
      ),
    },
  )
}

/// Render the summary bar with aggregate metrics.
let renderSummaryBar = (summary: SystemUpdateModule.updateSummary): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex gap-4 p-4 border-b border-gray-800"),
      Attrs.role("region"),
      Attrs.ariaLabel("Update summary"),
    },
    list{
      renderMetricCard("Total", summary.totalComponents, "text-gray-200"),
      renderMetricCard("Up to date", summary.upToDate, "text-green-400"),
      renderMetricCard("Updates", summary.updatesAvailable, "text-amber-400"),
      renderMetricCard("Failed", summary.failed, "text-red-400"),
      renderMetricCard("Updating", summary.updating, "text-blue-400"),
    },
  )
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

/// Render a status badge with appropriate color.
let renderStatusBadge = (status: SystemUpdateModule.updateStatus): Tea_Vdom.t<msg> => {
  let color = SystemUpdateModule.statusColor(status)
  let label = SystemUpdateModule.statusLabel(status)

  span(
    list{
      Attrs.class_("inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"),
      Attrs.prop("style", `background-color: ${color}20; color: ${color}; border: 1px solid ${color}40`),
      Attrs.ariaLabel(`Status: ${label}`),
    },
    list{text(label)},
  )
}

// ---------------------------------------------------------------------------
// Component row
// ---------------------------------------------------------------------------

/// Render a single component row in the table.
let renderComponentRow = (component: SystemUpdateModule.component): Tea_Vdom.t<msg> => {
  let canUpdate = switch component.status {
  | UpdateAvailable(_) => true
  | _ => false
  }

  div(
    list{
      Attrs.class_(
        "flex items-center gap-4 p-3 border-b border-gray-800/50 hover:bg-gray-900/40 transition-colors",
      ),
      Attrs.role("row"),
    },
    list{
      // Name
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 truncate")}, list{text(component.name)}),
          div(
            list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
            list{text(`Managed by ${component.managed_by}`)},
          ),
        },
      ),
      // Current version
      div(
        list{Attrs.class_("w-28 text-right")},
        list{
          span(
            list{Attrs.class_("text-sm font-mono text-gray-300")},
            list{text(component.currentVersion)},
          ),
        },
      ),
      // Latest version
      div(
        list{Attrs.class_("w-28 text-right")},
        list{
          span(
            list{Attrs.class_("text-sm font-mono text-gray-400")},
            list{
              text(
                switch component.latestVersion {
                | Some(v) => v
                | None => "-"
                },
              ),
            },
          ),
        },
      ),
      // Status badge
      div(list{Attrs.class_("w-40 text-center")}, list{renderStatusBadge(component.status)}),
      // Update button
      div(
        list{Attrs.class_("w-20 text-right")},
        list{
          if canUpdate {
            button(
              list{
                Attrs.class_(
                  "px-3 py-1 text-xs rounded bg-amber-600 hover:bg-amber-500 text-white transition-colors",
                ),
                Events.onClick(SystemUpdate(ApplyComponent(component.id))),
                Attrs.ariaLabel(`Update ${component.name}`),
              },
              list{text("Update")},
            )
          } else {
            text("")
          },
        },
      ),
    },
  )
}

// ---------------------------------------------------------------------------
// Category group
// ---------------------------------------------------------------------------

/// Render a category header and its components.
let renderCategoryGroup = (
  category: SystemUpdateModule.componentCategory,
  components: array<SystemUpdateModule.component>,
): Tea_Vdom.t<msg> => {
  let label = SystemUpdateModule.categoryLabel(category)
  let count = Array.length(components)

  div(
    list{
      Attrs.class_("mb-4"),
      Attrs.role("group"),
      Attrs.ariaLabel(`${label} (${Int.toString(count)} components)`),
    },
    list{
      // Category header
      div(
        list{Attrs.class_("flex items-center gap-2 px-3 py-2 bg-gray-900/80 rounded-t")},
        list{
          span(list{Attrs.class_("text-sm font-semibold text-gray-300")}, list{text(label)}),
          span(
            list{Attrs.class_("text-xs text-gray-500 px-2 py-0.5 rounded-full bg-gray-800")},
            list{text(Int.toString(count))},
          ),
        },
      ),
      // Component rows
      div(
        list{Attrs.class_("border border-gray-800/50 rounded-b")},
        list{
          ...Array.map(components, renderComponentRow)->List.fromArray
        },
      ),
    },
  )
}

// ---------------------------------------------------------------------------
// Component table
// ---------------------------------------------------------------------------

/// Render the full component table, grouped by category.
let renderComponentTable = (components: array<SystemUpdateModule.component>): Tea_Vdom.t<msg> => {
  // Group components by category
  let categories: array<SystemUpdateModule.componentCategory> = [
    BaseOS,
    Firmware,
    Toolchain,
    Runtime,
    PackageManager,
    Desktop,
  ]

  div(
    list{
      Attrs.class_("p-4 overflow-y-auto"),
      Attrs.role("table"),
      Attrs.ariaLabel("System components"),
    },
    list{
      // Column headers
      div(
        list{
          Attrs.class_("flex items-center gap-4 px-3 py-2 mb-2 text-xs text-gray-500 uppercase tracking-wider"),
          Attrs.role("row"),
        },
        list{
          div(list{Attrs.class_("flex-1")}, list{text("Component")}),
          div(list{Attrs.class_("w-28 text-right")}, list{text("Current")}),
          div(list{Attrs.class_("w-28 text-right")}, list{text("Latest")}),
          div(list{Attrs.class_("w-40 text-center")}, list{text("Status")}),
          div(list{Attrs.class_("w-20 text-right")}, list{text("Action")}),
        },
      ),
      // Category groups
      ...Array.map(categories, category => {
        let filtered = Array.filter(components, c => c.category == category)
        if Array.length(filtered) > 0 {
          renderCategoryGroup(category, filtered)
        } else {
          text("")
        }
      })->List.fromArray,
    },
  )
}

// ---------------------------------------------------------------------------
// Action bar
// ---------------------------------------------------------------------------

/// Render the action bar with Check All, Update All, and utility buttons.
let renderActionBar = (isLoading: bool): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-center gap-3 p-4 border-t border-gray-800 bg-gray-950/60"),
      Attrs.role("toolbar"),
      Attrs.ariaLabel("Update actions"),
    },
    list{
      button(
        list{
          Attrs.class_(
            "px-4 py-2 text-sm rounded bg-blue-600 hover:bg-blue-500 text-white transition-colors disabled:opacity-50",
          ),
          Events.onClick(SystemUpdate(CheckAll)),
          KeyboardNav.onActivate(SystemUpdate(CheckAll)),
          Attrs.disabled(isLoading),
          Attrs.ariaLabel("Check all components for updates"),
        },
        list{text(isLoading ? "Checking..." : "Check All")},
      ),
      button(
        list{
          Attrs.class_(
            "px-4 py-2 text-sm rounded bg-amber-600 hover:bg-amber-500 text-white transition-colors disabled:opacity-50",
          ),
          Events.onClick(SystemUpdate(ApplyAll)),
          KeyboardNav.onActivate(SystemUpdate(ApplyAll)),
          Attrs.disabled(isLoading),
          Attrs.ariaLabel("Apply all available updates"),
        },
        list{text("Update All")},
      ),
      div(list{Attrs.class_("flex-1")}, list{}),
      button(
        list{
          Attrs.class_(
            "px-3 py-2 text-sm rounded bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors",
          ),
          Events.onClick(SystemUpdate(AsdfStatus)),
          KeyboardNav.onActivate(SystemUpdate(AsdfStatus)),
          Attrs.ariaLabel("View asdf plugin details"),
        },
        list{text("asdf Details")},
      ),
      button(
        list{
          Attrs.class_(
            "px-3 py-2 text-sm rounded bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors",
          ),
          Events.onClick(SystemUpdate(ToggleShowLogs)),
          KeyboardNav.onActivate(SystemUpdate(ToggleShowLogs)),
          Attrs.ariaLabel("View update history"),
        },
        list{text("Logs")},
      ),
    },
  )
}

// ---------------------------------------------------------------------------
// Log viewer
// ---------------------------------------------------------------------------

/// Render the log viewer (collapsible).
let renderLogViewer = (
  logs: array<{.."timestamp": string, "summary": string}>,
  visible: bool,
): Tea_Vdom.t<msg> => {
  if !visible {
    text("")
  } else {
    div(
      list{
        Attrs.class_("p-4 border-t border-gray-800 bg-gray-950/80 max-h-64 overflow-y-auto"),
        Attrs.role("log"),
        Attrs.ariaLabel("Update log history"),
      },
      list{
        div(
          list{Attrs.class_("flex items-center justify-between mb-3")},
          list{
            span(
              list{Attrs.class_("text-sm font-semibold text-gray-300")},
              list{text("Update History")},
            ),
            button(
              list{
                Attrs.class_("text-xs text-gray-500 hover:text-gray-300"),
                Events.onClick(SystemUpdate(ToggleShowLogs)),
                KeyboardNav.onActivate(SystemUpdate(ToggleShowLogs)),
              },
              list{text("Close")},
            ),
          },
        ),
        ...Array.map(logs, entry =>
          div(
            list{Attrs.class_("flex gap-3 py-1 text-xs border-b border-gray-800/30")},
            list{
              span(
                list{Attrs.class_("text-gray-500 w-32 shrink-0 font-mono")},
                list{text(entry["timestamp"])},
              ),
              span(list{Attrs.class_("text-gray-400")}, list{text(entry["summary"])}),
            },
          )
        )->List.fromArray,
      },
    )
  }
}

// ---------------------------------------------------------------------------
// Root view
// ---------------------------------------------------------------------------

/// Main view for the System Update panel.
/// Renders summary bar, component table, action bar, and optional log viewer.
let view = (model: model): Tea_Vdom.t<msg> => {
  let su = model.systemUpdate
  let summary = su.summary
  let components = su.components
  let isLoading = su.loading
  let logs = su.logs
  let showLogs = su.showLogs

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100"),
      Attrs.role("region"),
      Attrs.ariaLabel("System Update Panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center gap-3 px-4 py-3 border-b border-gray-800")},
        list{
          span(
            list{Attrs.class_("text-lg font-bold text-gray-100")},
            list{text("System Update")},
          ),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{
              text(
                `${Int.toString(summary.totalComponents)} components across ${Int.toString(6)} managers`,
              ),
            },
          ),
        },
      ),
      // Summary metrics
      renderSummaryBar(summary),
      // Component table (scrollable)
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        list{renderComponentTable(components)},
      ),
      // Log viewer (toggled)
      renderLogViewer(logs, showLogs),
      // Action bar (fixed at bottom)
      renderActionBar(isLoading),
    },
  )
}
