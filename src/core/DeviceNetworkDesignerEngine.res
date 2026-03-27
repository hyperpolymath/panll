// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Device Network Designer Engine — pure computation and helpers for
/// wiring devices, configuring security levels, and validating topology.
///
/// Provides default state, tab labels, and utility functions for counting
/// devices by type, counting connections, and summarising validation results.

open DeviceNetworkDesignerModel

/// Default state for the Device Network Designer panel.
let defaultState: deviceNetworkDesignerState = {
  activeTab: Designer,
  devices: [],
  connections: [],
  validation: None,
  selectedDevice: None,
  selectedConnection: None,
  wiringMode: false,
  error: None,
}

/// Human-readable label for a device network designer category tab.
let tabLabel = (cat: deviceNetworkDesignerCategory): string =>
  switch cat {
  | Designer => "Designer"
  | Devices => "Devices"
  | Wiring => "Wiring"
  | Validation => "Validation"
  }

/// All category tabs in display order.
let allTabs: array<deviceNetworkDesignerCategory> = [Designer, Devices, Wiring, Validation]

/// Count devices matching a given device type string.
let countDevicesByType = (devices: array<deviceNode>, deviceType: string): int =>
  devices->Array.filter(d => d.deviceType === deviceType)->Array.length

/// Count total wire connections.
let countConnections = (connections: array<wireConnection>): int => connections->Array.length

/// Produce a human-readable validation summary string.
/// Returns "No validation run" if no result is available.
let validationSummary = (validation: option<networkValidation>): string =>
  switch validation {
  | None => "No validation run"
  | Some(v) => {
      let status = v.valid ? "PASS" : "FAIL"
      let errorCount = v.errors->Array.length
      let warningCount = v.warnings->Array.length
      `${status}: ${Int.toString(v.deviceCount)} devices, ${Int.toString(
          v.connectionCount,
        )} connections, ${Int.toString(errorCount)} errors, ${Int.toString(warningCount)} warnings`
    }
  }
