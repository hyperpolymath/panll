// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL AmbientOps Engine — pure helpers for hospital-model sysadmin panel.

open AmbientOpsModel

/// Default initial state.
let defaultState: ambientOpsState = {
  activeTab: TabDashboard,
  findings: [],
  scanning: false,
  error: None,
  clinicianAvailable: false,
  networkRepairAvailable: false,
  hardwareCrashTeamAvailable: false,
}

/// Tab label for display.
let tabLabel = (tab: ambientOpsTab): string => {
  switch tab {
  | TabDashboard => "Dashboard"
  | TabClinician => "Clinician"
  | TabNetwork => "Network"
  | TabHardware => "Hardware"
  | TabEmergency => "Emergency"
  }
}

/// All tabs for rendering.
let allTabs: array<ambientOpsTab> = [
  TabDashboard, TabClinician, TabNetwork, TabHardware, TabEmergency,
]

/// Department label for display.
let departmentLabel = (d: department): string => {
  switch d {
  | Clinician => "Clinician"
  | NetworkAmbulance => "Network Ambulance"
  | HardwareCrashTeam => "Hardware Crash Team"
  | EmergencyRoom => "Emergency Room"
  | AmbientObservatory => "Observatory"
  }
}

/// Severity label for display.
let severityLabel = (s: diagnosticSeverity): string => {
  switch s {
  | Info => "Info"
  | Warning => "Warning"
  | Error => "Error"
  | Critical => "Critical"
  }
}

/// Count findings by severity.
let countBySeverity = (findings: array<diagnosticFinding>, target: diagnosticSeverity): int => {
  findings->Array.filter(f => f.severity == target)->Array.length
}

/// Count findings by department.
let countByDepartment = (findings: array<diagnosticFinding>, target: department): int => {
  findings->Array.filter(f => f.department == target)->Array.length
}

/// Filter findings for a specific department.
let findingsForDepartment = (findings: array<diagnosticFinding>, target: department): array<diagnosticFinding> => {
  findings->Array.filter(f => f.department == target)
}
