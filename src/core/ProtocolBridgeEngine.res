// SPDX-License-Identifier: MPL-2.0

/// PanLL Protocol Bridge Engine — pure computation and helpers for the
/// Protocol Bridge panel. Provides default state, tab metadata, channel
/// counting, latency aggregation, and protocol rule formatting.

open ProtocolBridgeModel

/// Default state for the Protocol Bridge panel.
/// Starts on the Channels tab with empty channel, message, and rule lists.
let defaultState: protocolBridgeState = {
  activeTab: Channels,
  channels: [],
  messageLog: [],
  latencySamples: [],
  protocolRules: [],
  connected: false,
  error: None,
}

/// Human-readable label for each tab in the Protocol Bridge panel.
let tabLabel = (tab: protocolBridgeTab): string =>
  switch tab {
  | Channels => "Channels"
  | Messages => "Messages"
  | Latency => "Latency"
  | Rules => "Rules"
  }

/// All tabs in display order.
let allTabs: array<protocolBridgeTab> = [Channels, Messages, Latency, Rules]

/// Count channels that are currently connected (Active, Idle, or Degraded).
let countConnectedChannels = (channels: array<channel>): int =>
  channels
  ->Array.filter(ch =>
    switch ch.status {
    | ChannelActive | ChannelIdle | ChannelDegraded => true
    | ChannelDisconnected | ChannelError => false
    }
  )
  ->Array.length

/// Count channels matching a given status.
let countChannelsByStatus = (channels: array<channel>, status: channelStatus): int =>
  channels->Array.filter(ch => ch.status === status)->Array.length

/// Human-readable label for a channel status.
let channelStatusLabel = (status: channelStatus): string =>
  switch status {
  | ChannelActive => "Active"
  | ChannelIdle => "Idle"
  | ChannelDegraded => "Degraded"
  | ChannelDisconnected => "Disconnected"
  | ChannelError => "Error"
  }

/// Compute the average latency across all channels (in milliseconds).
/// Returns 0.0 when there are no channels.
let averageLatency = (channels: array<channel>): float => {
  let count = Array.length(channels)
  if count === 0 {
    0.0
  } else {
    let total = channels->Array.reduce(0.0, (acc, ch) => acc +. ch.latencyMs)
    total /. Int.toFloat(count)
  }
}

/// Compute the average latency from recorded samples (in milliseconds).
/// Returns 0.0 when there are no samples.
let averageSampleLatency = (samples: array<protocolLatencySample>): float => {
  let count = Array.length(samples)
  if count === 0 {
    0.0
  } else {
    let total = samples->Array.reduce(0.0, (acc, s) => acc +. s.latencyMs)
    total /. Int.toFloat(count)
  }
}

/// Count latency samples that exceeded the acceptable threshold.
let countExceededThreshold = (samples: array<protocolLatencySample>): int =>
  samples->Array.filter(s => s.exceededThreshold)->Array.length

/// Format a protocol rule as a human-readable summary string.
/// Includes the rule name, status indicator, and expression.
let formatProtocolRule = (rule: protocolRule): string => {
  let statusTag = switch rule.status {
  | RuleVerified => "[Verified]"
  | RuleUnverified => "[Unverified]"
  | RuleViolated => "[Violated]"
  }
  `${statusTag} ${rule.name}: ${rule.expression}`
}
