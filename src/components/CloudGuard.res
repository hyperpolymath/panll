// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard — Main Cloudflare domain security management panel.
///
/// Full-screen overlay panel (like VAB) that provides the Panel-W dashboard
/// for managing Cloudflare domains. Contains the domain selector ribbon,
/// category tab bar, settings toggle grid, action bar, and side panels
/// for audit results and config diffs.
///
/// Layout (see plan for full ASCII art):
///   +-------------------------------------------------------+
///   | [Domain Ribbon: checkboxes for each domain]           |
///   | [Select All] [None] [Filter: _____]                   |
///   +-------------------------------------------------------+
///   | SSL/TLS | Headers | WAF | Bot | DNS | ... | DNSSEC    |  <-- Category tabs
///   +---------------------------+---------------------------+
///   | Settings Toggle Grid      | Compliance Audit          |
///   | (toggles, dropdowns,      | (passed/failed/warnings,  |
///   |  number inputs per        |  findings list,           |
///   |  category)                |  config diff summary)     |
///   +---------------------------+---------------------------+
///   | [Harden All] [Push Changes] [Download] [Audit]        |  <-- Action bar
///   | Progress: 28/36 domains hardened                       |
///   +-------------------------------------------------------+

open Msg
open Model
open Tea.Html

// ============================================================================
// Category tab bar
// ============================================================================

/// All setting categories in display order.
let allCategories: array<settingCategory> = [
  SslTls,
  Headers,
  Waf,
  BotDefense,
  Dns,
  EmailSec,
  Performance,
  Network,
  Pages,
  Dnssec,
]

/// Render a single category tab button.
let renderCategoryTab = (
  cat: settingCategory,
  isActive: bool,
): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"

  button(
    list{
      Attrs.class_(
        `px-3 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors ${activeClass}`,
      ),
      Attrs.ariaSelected(Bool.toString(isActive)),
      Attrs.role("tab"),
      Events.onClick(CloudGuard(SetCategory(cat))),
    },
    list{text(CloudGuardCatalog.categoryLabel(cat))},
  )
}

/// Render the full category tab bar.
let renderCategoryTabBar = (activeCategory: settingCategory): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Setting categories"),
    },
    allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

// ============================================================================
// Connection status bar
// ============================================================================

/// Render the connection status indicator.
let renderConnectionStatus = (connection: cfConnectionStatus): Tea_Vdom.t<msg> => {
  let (dotClass, statusText) = switch connection {
  | Disconnected => ("bg-gray-500", "Not connected")
  | Connecting => ("bg-yellow-400 animate-pulse", "Connecting...")
  | Connected(info) => ("bg-green-400", `Connected: ${info}`)
  | ConnectionError(err) => ("bg-red-400", `Error: ${err}`)
  }

  div(
    list{Attrs.class_("flex items-center gap-2 px-3 py-1.5")},
    list{
      span(
        list{Attrs.class_(`w-2 h-2 rounded-full ${dotClass}`)},
        list{},
      ),
      span(
        list{Attrs.class_("text-xs text-gray-400")},
        list{text(statusText)},
      ),
    },
  )
}

// ============================================================================
// Audit side panel
// ============================================================================

/// Render the audit results summary in the right side panel.
let renderAuditPanel = (
  auditResult: option<auditResult>,
  loading: bool,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("w-72 border-l border-gray-800 p-3 overflow-y-auto")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-3 font-medium")},
        list{text("COMPLIANCE AUDIT")},
      ),
      switch auditResult {
      | None =>
        if loading {
          div(
            list{Attrs.class_("text-sm text-gray-500 italic")},
            list{text("Running audit...")},
          )
        } else {
          div(
            list{Attrs.class_("text-sm text-gray-600 italic")},
            list{text("Click 'Audit' to check compliance")},
          )
        }
      | Some(result) =>
        div(
          list{},
          list{
            // Score summary
            div(
              list{Attrs.class_("flex items-center gap-3 mb-3")},
              list{
                div(
                  list{Attrs.class_("text-2xl font-bold text-indigo-300")},
                  list{text(`${Float.toFixed(result.score *. 100.0, ~digits=0)}%`)},
                ),
                div(
                  list{},
                  list{
                    div(
                      list{Attrs.class_("text-xs text-green-400")},
                      list{text(`${Int.toString(result.passed)} passed`)},
                    ),
                    div(
                      list{Attrs.class_("text-xs text-red-400")},
                      list{text(`${Int.toString(result.failed)} failed`)},
                    ),
                  },
                ),
              },
            ),
            // Findings list
            div(
              list{Attrs.class_("space-y-2")},
              result.findings
              ->CloudGuardEngine.sortFindingsBySeverity
              ->Array.map(finding =>
                div(
                  list{Attrs.class_("text-xs p-2 bg-gray-800/50 rounded")},
                  list{
                    div(
                      list{Attrs.class_("flex items-center gap-1.5 mb-1")},
                      list{
                        span(
                          list{Attrs.class_(`font-bold ${CloudGuardEngine.severityColour(finding.severity)}`)},
                          list{text(CloudGuardEngine.severityLabel(finding.severity))},
                        ),
                        span(
                          list{Attrs.class_("text-gray-400")},
                          list{text(finding.settingId)},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-gray-400")},
                      list{text(finding.message)},
                    ),
                  },
                )
              )
              ->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

// ============================================================================
// Action bar
// ============================================================================

/// Render the bottom action bar with Harden All, Push, Download, Audit buttons.
let renderActionBar = (
  selectedCount: int,
  totalCount: int,
  loading: bool,
  bulkProgress: option<bulkProgress>,
): Tea_Vdom.t<msg> => {
  let buttonClass = "px-3 py-1.5 text-sm font-medium rounded cursor-pointer transition-colors"
  let primaryClass = `${buttonClass} bg-indigo-600 hover:bg-indigo-500 text-white`
  let secondaryClass = `${buttonClass} bg-gray-700 hover:bg-gray-600 text-gray-200`
  let disabledClass = `${buttonClass} bg-gray-800 text-gray-600 cursor-not-allowed`

  div(
    list{Attrs.class_("border-t border-gray-800 px-4 py-3 flex items-center justify-between")},
    list{
      // Action buttons
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          button(
            list{
              Attrs.class_(if selectedCount > 0 && !loading { primaryClass } else { disabledClass }),
              Attrs.ariaLabel("Harden all selected domains"),
              if selectedCount > 0 && !loading {
                Events.onClick(CloudGuard(HardenSelected))
              } else {
                Attrs.noProp
              },
            },
            list{text("Harden All")},
          ),
          button(
            list{
              Attrs.class_(if !loading { secondaryClass } else { disabledClass }),
              Attrs.ariaLabel("Push local changes to Cloudflare"),
              if !loading {
                Events.onClick(CloudGuard(PushChanges))
              } else {
                Attrs.noProp
              },
            },
            list{text("Push Changes")},
          ),
          button(
            list{
              Attrs.class_(if !loading { secondaryClass } else { disabledClass }),
              Attrs.ariaLabel("Download offline config"),
              if !loading {
                Events.onClick(CloudGuard(DownloadConfig))
              } else {
                Attrs.noProp
              },
            },
            list{text("Download")},
          ),
          button(
            list{
              Attrs.class_(if selectedCount > 0 && !loading { secondaryClass } else { disabledClass }),
              Attrs.ariaLabel("Run compliance audit"),
              if selectedCount > 0 && !loading {
                Events.onClick(CloudGuard(RunAudit))
              } else {
                Attrs.noProp
              },
            },
            list{text("Audit")},
          ),
        },
      ),
      // Progress indicator
      switch bulkProgress {
      | None =>
        div(
          list{Attrs.class_("text-xs text-gray-500")},
          list{
            text(`${Int.toString(selectedCount)}/${Int.toString(totalCount)} domains selected`),
          },
        )
      | Some(progress) =>
        div(
          list{Attrs.class_("flex items-center gap-2")},
          list{
            // Progress bar
            div(
              list{Attrs.class_("w-40 h-2 bg-gray-800 rounded-full overflow-hidden")},
              list{
                div(
                  list{
                    Attrs.class_("h-full bg-indigo-500 transition-all"),
                    Attrs.style(
                      "width",
                      `${Float.toFixed(
                        Int.toFloat(progress.completed) /. Int.toFloat(if progress.total > 0 { progress.total } else { 1 }) *. 100.0,
                        ~digits=0,
                      )}%`,
                    ),
                  },
                  list{},
                ),
              },
            ),
            // Progress text
            div(
              list{Attrs.class_("text-xs text-gray-400")},
              list{
                text(
                  `${Int.toString(progress.completed)}/${Int.toString(progress.total)} domains`,
                ),
              },
            ),
            // Current domain
            switch progress.currentDomain {
            | Some(domain) =>
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(domain)},
              )
            | None => noNode
            },
          },
        )
      },
    },
  )
}

// ============================================================================
// Main panel view
// ============================================================================

/// Render the complete CloudGuard panel as a full-screen overlay.
/// This is the Panel-W component for the CloudGuard module.
let view = (state: cloudguardState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 z-50 bg-gray-950 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("CloudGuard — Cloudflare Domain Security Management"),
    },
    list{
      // Header bar with title, connection status, and close button
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800 bg-gray-900/80")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              div(
                list{Attrs.class_("text-lg font-semibold text-gray-200")},
                list{text("CloudGuard")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Cloudflare Domain Security")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              renderConnectionStatus(state.connection),
              button(
                list{
                  Attrs.class_("text-gray-500 hover:text-gray-300 cursor-pointer text-lg px-2"),
                  Attrs.ariaLabel("Close CloudGuard"),
                  Events.onClick(CloudGuard(ToggleCloudGuard)),
                },
                list{text("x")},
              ),
            },
          ),
        },
      ),

      // Domain selector ribbon
      div(
        list{Attrs.class_("px-4 py-2")},
        list{
          CloudGuardDomainList.view(state.zones, state.selectedZoneIds, state.filterText),
        },
      ),

      // Category tab bar
      div(
        list{Attrs.class_("px-4")},
        list{renderCategoryTabBar(state.activeCategory)},
      ),

      // Main content area: settings grid + audit side panel
      div(
        list{Attrs.class_("flex-1 flex overflow-hidden")},
        list{
          // Settings grid (left/main)
          div(
            list{Attrs.class_("flex-1 overflow-y-auto px-4 py-2")},
            list{
              CloudGuardSettingsGrid.view(state.settings, state.activeCategory, state.settingFilter),
            },
          ),
          // Audit side panel (right)
          if state.showAudit {
            renderAuditPanel(state.auditResult, state.loading)
          } else {
            noNode
          },
        },
      ),

      // Action bar (bottom)
      renderActionBar(
        Array.length(state.selectedZoneIds),
        Array.length(state.zones),
        state.loading,
        state.bulkProgress,
      ),
    },
  )
}
