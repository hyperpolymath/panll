// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Panel Bus -- subscriber management.

type panelBusMsg =
  /// Subscribe a clade to specific topics.
  | BusSubscribe(string, array<PanelBus.eventTopic>)
  /// Unsubscribe a clade from the bus.
  | BusUnsubscribe(string)
  /// Clear the event history ring buffer.
  | BusClearHistory
