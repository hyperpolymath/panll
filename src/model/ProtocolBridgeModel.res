// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Protocol Bridge Model — connects sync protocol management to IDApTIK
/// game development. Bridges PanLL's protocol analysis with multiplayer
/// synchronisation, message format verification, and latency monitoring.
///
/// Three-panel model (L/N/W):
///   L: Sync protocol rules, message format specifications
///   N: Protocol analysis reasoning about correctness and performance
///   W: Channel status dashboard with latency graphs
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Protocol Bridge panel.
type protocolBridgeTab =
  /// Channels — browse and monitor active sync channels.
  | Channels
  /// Messages — inspect the message log with format details.
  | Messages
  /// Latency — latency sample graphs and percentile analysis.
  | Latency
  /// Rules — define and verify protocol rules and format specs.
  | Rules

// ============================================================================
// Channel Domain
// ============================================================================

/// Connection status of a sync channel.
type channelStatus =
  /// Active — channel is connected and transmitting.
  | ChannelActive
  /// Idle — channel is connected but no recent traffic.
  | ChannelIdle
  /// Degraded — channel is experiencing packet loss or high latency.
  | ChannelDegraded
  /// Disconnected — channel is not connected.
  | ChannelDisconnected
  /// Error — channel encountered a protocol error.
  | ChannelError

/// A sync channel connecting game clients or services.
type channel = {
  /// Unique channel identifier.
  id: string,
  /// Human-readable channel name (e.g., "PlayerSync", "WorldState").
  name: string,
  /// Current connection status.
  status: channelStatus,
  /// Number of active subscribers on this channel.
  subscribers: int,
  /// Current latency in milliseconds (round-trip).
  latencyMs: float,
  /// Protocol used by this channel (e.g., "WebSocket", "UDP", "QUIC").
  protocol: string,
}

// ============================================================================
// Message Log
// ============================================================================

/// Direction of a protocol message.
type messageDirection =
  /// Inbound — message received from a remote peer.
  | MessageInbound
  /// Outbound — message sent to a remote peer.
  | MessageOutbound

/// A single entry in the protocol message log.
type messageLogEntry = {
  /// Unique message identifier.
  id: string,
  /// Channel this message was transmitted on.
  channelId: string,
  /// Direction of the message.
  direction: messageDirection,
  /// Message type or opcode name.
  messageType: string,
  /// Payload size in bytes.
  payloadBytes: int,
  /// Timestamp (milliseconds since epoch).
  timestamp: float,
  /// Whether this message passed format validation.
  valid: bool,
  /// Validation error message if invalid.
  validationError: option<string>,
}

// ============================================================================
// Latency Monitoring
// ============================================================================

/// A single latency measurement sample.
type protocolLatencySample = {
  /// Channel this sample was measured on.
  channelId: string,
  /// Latency in milliseconds (round-trip).
  latencyMs: float,
  /// Timestamp when the sample was recorded (milliseconds since epoch).
  timestamp: float,
  /// Whether this sample exceeds the acceptable threshold.
  exceededThreshold: bool,
}

// ============================================================================
// Protocol Rules
// ============================================================================

/// Verification status of a protocol rule.
type protocolRuleStatus =
  /// Verified — rule has been formally checked and holds.
  | RuleVerified
  /// Unverified — rule has not been checked yet.
  | RuleUnverified
  /// Violated — a violation was detected in the message log.
  | RuleViolated

/// A protocol rule defining expected message format or behaviour.
type protocolRule = {
  /// Unique rule identifier.
  id: string,
  /// Human-readable rule name (e.g., "MaxPayloadSize", "OrderGuarantee").
  name: string,
  /// Formal rule expression.
  expression: string,
  /// Verification status.
  status: protocolRuleStatus,
  /// Human-readable description of what this rule enforces.
  description: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Protocol Bridge panel.
type protocolBridgeState = {
  /// Active tab within the Protocol Bridge panel.
  activeTab: protocolBridgeTab,
  /// All registered sync channels.
  channels: array<channel>,
  /// Protocol message log (most recent first).
  messageLog: array<messageLogEntry>,
  /// Latency measurement samples.
  latencySamples: array<protocolLatencySample>,
  /// Protocol rules and format specifications.
  protocolRules: array<protocolRule>,
  /// Whether the protocol monitor is connected.
  connected: bool,
  /// Error from the last operation.
  error: option<string>,
}
