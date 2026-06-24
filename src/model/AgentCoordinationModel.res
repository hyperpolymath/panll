// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Coordination View Model — types for multi-agent topology
/// and coordination strategy management.
///
/// Displays agent nodes in a topology with their coordination strategies,
/// memory types, and inter-agent relationships.
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Coordination Strategies
// ============================================================================

/// Multi-agent coordination strategy.
type coordination =
  /// Solo — single agent, no coordination needed.
  | Solo
  /// Pipeline — agents arranged in a sequential chain.
  | Pipeline
  /// Broadcast — one agent sends to all others.
  | Broadcast
  /// Consensus — agents must agree before proceeding.
  | Consensus
  /// Hierarchy — tree-shaped delegation with a root coordinator.
  | Hierarchy
  /// Swarm — decentralised, agents self-organise.
  | Swarm

// ============================================================================
// Memory Types
// ============================================================================

/// Type of memory available to an agent node.
type memoryType =
  /// Ephemeral — in-memory only, lost on restart.
  | Ephemeral
  /// Session — persists for the duration of an OODA session.
  | Session
  /// Persistent — survives across sessions (disk/database).
  | Persistent
  /// Shared — accessible by multiple agents simultaneously.
  | Shared
  /// Immutable — write-once append-only log.
  | Immutable

// ============================================================================
// Agent Nodes and Topology
// ============================================================================

/// Agent operational state within the topology.
type agentNodeState =
  /// Active — agent is running and responsive.
  | Active
  /// Idle — agent is registered but not currently executing.
  | Idle
  /// Disconnected — agent is unreachable.
  | Disconnected
  /// Error — agent has encountered a fault.
  | NodeError

/// A single agent node in the coordination topology.
type agentNode = {
  /// Unique node identifier.
  id: string,
  /// Human-readable agent name.
  name: string,
  /// Current operational state.
  state: agentNodeState,
  /// Coordination strategy this agent participates in.
  strategy: coordination,
  /// Memory types available to this agent.
  memoryTypes: array<memoryType>,
}

/// An edge connecting two agent nodes in the topology.
type topologyEdge = {
  /// Source agent node id.
  fromId: string,
  /// Target agent node id.
  toId: string,
  /// Label describing the relationship (e.g., "delegates", "broadcasts").
  label: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Top-level state for the Agent Coordination View panel.
type agentCoordinationState = {
  /// All agent nodes in the topology.
  nodes: array<agentNode>,
  /// Edges connecting agent nodes.
  edges: array<topologyEdge>,
  /// Currently selected coordination strategy for overview.
  selectedStrategy: option<coordination>,
  /// Whether topology data is being loaded.
  loading: bool,
}
