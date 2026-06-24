// SPDX-License-Identifier: MPL-2.0

/// PanLL Device Network Designer Model — types for wiring devices,
/// configuring security levels, and validating network topology.
///
/// Devices are placed as nodes on a canvas and connected with typed
/// wire connections. Each connection has a protocol, encryption flag,
/// and bandwidth rating. The validation engine checks for orphaned
/// devices, security mismatches, and topology errors.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// A device node placed on the network design canvas.
type deviceNode = {
  /// Unique identifier for this device.
  id: string,
  /// Device type name (e.g., "Router", "Server", "Camera", "Firewall").
  deviceType: string,
  /// X position on the canvas in world coordinates.
  x: float,
  /// Y position on the canvas in world coordinates.
  y: float,
  /// Security level tier (0 = open, higher = more restricted).
  securityLevel: int,
  /// Zone name this device belongs to (e.g., "LAN", "DMZ", "SCADA").
  zone: string,
  /// Key-value properties for this device instance.
  properties: Dict.t<string>,
}

/// A wire connection between two devices.
type wireConnection = {
  /// Unique identifier for this connection.
  id: string,
  /// ID of the source device.
  fromDevice: string,
  /// ID of the destination device.
  toDevice: string,
  /// Protocol name (e.g., "TCP", "UDP", "SSH", "HTTPS", "Modbus").
  protocol: string,
  /// Whether the connection is encrypted.
  encrypted: bool,
  /// Bandwidth rating (e.g., "1Gbps", "100Mbps", "10Mbps").
  bandwidth: string,
}

/// Result of validating the network topology.
type networkValidation = {
  /// Whether the entire network passes validation.
  valid: bool,
  /// Critical errors that must be fixed.
  errors: array<string>,
  /// Non-critical warnings to review.
  warnings: array<string>,
  /// Total number of devices in the network.
  deviceCount: int,
  /// Total number of connections in the network.
  connectionCount: int,
}

/// Category tabs for the Device Network Designer panel.
type deviceNetworkDesignerCategory =
  /// Visual canvas for placing and connecting devices.
  | Designer
  /// Device catalogue and properties inspector.
  | Devices
  /// Wire connection list and configuration.
  | Wiring
  /// Network topology validation results.
  | Validation

/// Root state for the Device Network Designer panel.
type deviceNetworkDesignerState = {
  /// Active category tab.
  activeTab: deviceNetworkDesignerCategory,
  /// All devices placed on the design canvas.
  devices: array<deviceNode>,
  /// All wire connections between devices.
  connections: array<wireConnection>,
  /// Most recent network validation result (if any).
  validation: option<networkValidation>,
  /// ID of the currently selected device (if any).
  selectedDevice: option<string>,
  /// ID of the currently selected connection (if any).
  selectedConnection: option<string>,
  /// Whether wiring mode is active (click devices to connect).
  wiringMode: bool,
  /// Error message (if any).
  error: option<string>,
}
