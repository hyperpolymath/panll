// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AmbientOps Component — hospital-model sysadmin operations panel.
///
/// Integrates the AmbientOps framework departments:
///   - Clinician: AI-assisted sysadmin diagnostics (Rust)
///   - Network Ambulance: Network repair (Ada/SPARK + bash)
///   - Hardware Crash Team: GPU/PCIe diagnostics (Rust)
///   - Emergency Room: Panic-safe intake (V)
///   - Observatory: System weather (Elixir)

open Model
open Msg
open Tea.Html

/// Render a severity badge.
let severityBadge = (severity: diagnosticSeverity): Tea_Vdom.t<msg> => {
  let (color, label) = switch severity {
  | Info => ("text-blue-400", "INFO")
  | Warning => ("text-yellow-400", "WARN")
  | Error => ("text-red-400", "ERROR")
  | Critical => ("text-red-500 font-bold", "CRIT")
  }
  span(list{Attrs.class_("text-xs font-mono px-1 rounded " ++ color)}, list{text(label)})
}

/// Render a finding row.
let findingRow = (finding: diagnosticFinding): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-start gap-3 py-2 px-3 border-b border-gray-800"),
      Attrs.role("row"),
    },
    list{
      severityBadge(finding.severity),
      div(
        list{Attrs.class_("flex-1")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200")}, list{text(finding.summary)}),
          div(
            list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
            list{
              text(AmbientOpsEngine.departmentLabel(finding.department)),
              if finding.repairAvailable {
                span(list{Attrs.class_("ml-2 text-green-500")}, list{text("[repair available]")})
              } else {
                Tea_Html.noNode
              },
            },
          ),
        },
      ),
      span(list{Attrs.class_("text-xs text-gray-600 shrink-0")}, list{text(finding.timestamp)}),
    },
  )
}

/// Render a tab button.
let tabBtn = (current: ambientOpsTab, target: ambientOpsTab, label: string): Tea_Vdom.t<msg> => {
  let active = current == target
  button(
    list{
      Attrs.class_(
        "px-3 py-1 text-xs rounded " ++ if active {
          "bg-teal-700 text-white"
        } else {
          "bg-gray-800 text-gray-400 hover:bg-gray-700"
        },
      ),
      Events.onClick(AmbientOps(SetOpsTab(target))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Availability indicator.
let availDot = (available: bool, label: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 text-xs")},
    list{
      span(
        list{
          Attrs.class_(
            "w-2 h-2 rounded-full " ++ if available {
              "bg-green-400"
            } else {
              "bg-red-500"
            },
          ),
        },
        list{},
      ),
      span(
        list{
          Attrs.class_(
            if available {
              "text-gray-300"
            } else {
              "text-gray-600"
            },
          ),
        },
        list{text(label)},
      ),
    },
  )
}

/// Main view function for the AmbientOps panel.
let view = (state: ambientOpsState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("AmbientOps — Hospital-Model Sysadmin"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          h2(list{Attrs.class_("text-lg font-bold text-teal-300")}, list{text("AmbientOps")}),
          div(
            list{Attrs.class_("flex gap-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs rounded bg-teal-700 text-white hover:bg-teal-600",
                  ),
                  Events.onClick(AmbientOps(RunDiagnostics)),
                  KeyboardNav.onActivate(AmbientOps(RunDiagnostics)),
                },
                list{
                  text(
                    if state.scanning {
                      "Scanning..."
                    } else {
                      "Run Diagnostics"
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800"), Attrs.role("tablist")},
        list{
          tabBtn(state.activeTab, TabDashboard, "Dashboard"),
          tabBtn(state.activeTab, TabClinician, "Clinician"),
          tabBtn(state.activeTab, TabNetwork, "Network"),
          tabBtn(state.activeTab, TabHardware, "Hardware"),
          tabBtn(state.activeTab, TabEmergency, "Emergency"),
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
            Events.onClick(AmbientOps(DismissOpsError)),
            KeyboardNav.onActivate(AmbientOps(DismissOpsError)),
          },
          list{text(err)},
        )
      | None => Tea_Html.noNode
      },
      // Tool availability bar
      div(
        list{Attrs.class_("flex gap-6 px-4 py-2 border-b border-gray-800")},
        list{
          availDot(state.clinicianAvailable, "Clinician"),
          availDot(state.networkRepairAvailable, "Network Repair"),
          availDot(state.hardwareCrashTeamAvailable, "HW Crash Team"),
        },
      ),
      // Findings count summary
      div(
        list{Attrs.class_("flex gap-4 px-4 py-1 text-xs text-gray-400 border-b border-gray-800")},
        list{
          span(
            list{},
            list{
              text(
                "Critical: " ++
                Int.toString(AmbientOpsEngine.countBySeverity(state.findings, Critical)),
              ),
            },
          ),
          span(
            list{},
            list{
              text(
                "Errors: " ++ Int.toString(AmbientOpsEngine.countBySeverity(state.findings, Error)),
              ),
            },
          ),
          span(
            list{},
            list{
              text(
                "Warnings: " ++
                Int.toString(AmbientOpsEngine.countBySeverity(state.findings, Warning)),
              ),
            },
          ),
          span(list{}, list{text("Total: " ++ Int.toString(Array.length(state.findings)))}),
        },
      ),
      // Content — filtered findings
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        {
          let filtered = switch state.activeTab {
          | TabDashboard => state.findings
          | TabClinician => AmbientOpsEngine.findingsForDepartment(state.findings, Clinician)
          | TabNetwork => AmbientOpsEngine.findingsForDepartment(state.findings, NetworkAmbulance)
          | TabHardware => AmbientOpsEngine.findingsForDepartment(state.findings, HardwareCrashTeam)
          | TabEmergency => AmbientOpsEngine.findingsForDepartment(state.findings, EmergencyRoom)
          }
          if Array.length(filtered) == 0 {
            list{
              div(
                list{Attrs.class_("flex items-center justify-center h-32 text-gray-600 text-sm")},
                list{text("No findings. Run diagnostics to scan.")},
              ),
            }
          } else {
            filtered->Array.map(findingRow)->List.fromArray
          }
        },
      ),
    },
  )
}
