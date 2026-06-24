// SPDX-License-Identifier: MPL-2.0

/// PanLL AmbientOps Model — hospital-model sysadmin operations state.
///
/// Integrates the AmbientOps framework: clinician (AI-assisted sysadmin),
/// network ambulance (Ada/SPARK + bash diagnostics), hardware crash team
/// (Rust GPU/PCIe diagnostics), emergency room (V intake), and observatory
/// (Elixir metrics). Evidence Envelope pipeline for diagnostics and repairs.
///
/// This module has NO dependencies on other PanLL modules.

/// AmbientOps department — mirrors the hospital model.
type department =
  | Clinician // AI-assisted sysadmin (Rust)
  | NetworkAmbulance // Network diagnostics and repair (Ada/SPARK + bash)
  | HardwareCrashTeam // Hardware diagnostics (Rust)
  | EmergencyRoom // Panic-safe intake (V)
  | AmbientObservatory // System weather and metrics (Elixir)

/// Diagnostic severity from the Evidence Envelope.
type diagnosticSeverity =
  | Info
  | Warning
  | Error
  | Critical

/// A single diagnostic finding from an AmbientOps tool.
type diagnosticFinding = {
  /// Which department produced this finding.
  department: department,
  /// Severity level.
  severity: diagnosticSeverity,
  /// Short summary of the finding.
  summary: string,
  /// Detailed description.
  detail: string,
  /// Timestamp (ISO 8601).
  timestamp: string,
  /// Whether a repair is available for this finding.
  repairAvailable: bool,
}

/// AmbientOps panel tabs.
type ambientOpsTab =
  | TabDashboard // Overview of all departments
  | TabClinician // AI-assisted diagnostics
  | TabNetwork // Network ambulance
  | TabHardware // Hardware crash team
  | TabEmergency // Emergency room intake

/// Root state for the AmbientOps panel.
type ambientOpsState = {
  /// Active tab.
  activeTab: ambientOpsTab,
  /// Current findings from all departments.
  findings: array<diagnosticFinding>,
  /// Whether a diagnostic sweep is running.
  scanning: bool,
  /// Error from last scan.
  error: option<string>,
  /// Whether the clinician binary is available.
  clinicianAvailable: bool,
  /// Whether the network-repair tool is available.
  networkRepairAvailable: bool,
  /// Whether the hardware-crash-team binary is available.
  hardwareCrashTeamAvailable: bool,
}
