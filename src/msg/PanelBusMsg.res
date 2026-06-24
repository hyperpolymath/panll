// SPDX-License-Identifier: MPL-2.0

/// Messages for the Panel Bus -- subscriber management.

type panelBusMsg =
  /// Subscribe a clade to specific topics.
  | BusSubscribe(string, array<PanelBus.eventTopic>)
  /// Unsubscribe a clade from the bus.
  | BusUnsubscribe(string)
  /// Clear the event history ring buffer.
  | BusClearHistory
