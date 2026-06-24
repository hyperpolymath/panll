// SPDX-License-Identifier: MPL-2.0

/// PanLL Connection Manager — shared utilities for managing panel backend connections.
///
/// Provides pure helper functions for connection lifecycle state transitions.
/// Each panel maintains its own connectionStatus in its model; this module
/// offers common logic so panels behave consistently.

open PanelSwitcherModel

/// Transition a connection to "checking" state.
let startChecking = (_status: connectionStatus): connectionStatus => {
  ServiceChecking
}

/// Handle a successful health check response.
let connectSuccess = (_status: connectionStatus): connectionStatus => {
  ServiceConnected
}

/// Handle a failed health check response.
let connectFailure = (_status: connectionStatus, error: string): connectionStatus => {
  ServiceError(error)
}

/// Reset connection to disconnected.
let disconnect = (_status: connectionStatus): connectionStatus => {
  ServiceDisconnected
}

/// Check if a connection is usable (connected).
let isConnected = (status: connectionStatus): bool => {
  switch status {
  | ServiceConnected => true
  | _ => false
  }
}

/// Check if a connection is in an error state.
let hasError = (status: connectionStatus): bool => {
  switch status {
  | ServiceError(_) => true
  | _ => false
  }
}

/// Get the error message if in error state.
let errorMessage = (status: connectionStatus): option<string> => {
  switch status {
  | ServiceError(msg) => Some(msg)
  | _ => None
  }
}

/// Human-readable label for a connection status.
let statusLabel = (status: connectionStatus): string => {
  switch status {
  | ServiceConnected => "Connected"
  | ServiceDisconnected => "Disconnected"
  | ServiceChecking => "Checking..."
  | ServiceError(e) => `Error: ${e}`
  }
}

/// CSS colour class for a connection status.
let statusColour = (status: connectionStatus): string => {
  switch status {
  | ServiceConnected => "text-emerald-400"
  | ServiceDisconnected => "text-gray-500"
  | ServiceChecking => "text-amber-400"
  | ServiceError(_) => "text-red-400"
  }
}
