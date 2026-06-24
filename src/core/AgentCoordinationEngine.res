// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Coordination Engine — pure helpers for the coordination
/// view panel.
///
/// All functions are pure (no side effects). Provides coordination strategy
/// descriptions, memory type classification, topology layout helpers,
/// and node state colour mappings.

open AgentCoordinationModel

// ============================================================================
// Coordination Strategy Helpers
// ============================================================================

/// Whether a coordination strategy involves multiple agents.
let isMultiAgent = (strategy: coordination): bool => {
  switch strategy {
  | Solo => false
  | Pipeline => true
  | Broadcast => true
  | Consensus => true
  | Hierarchy => true
  | Swarm => true
  }
}

/// Human-readable description of a coordination strategy.
let strategyDescription = (strategy: coordination): string => {
  switch strategy {
  | Solo => "Single agent operating independently. No inter-agent communication."
  | Pipeline => "Sequential chain — each agent passes output to the next."
  | Broadcast => "One coordinator sends instructions to all agents simultaneously."
  | Consensus => "All agents must agree before any action is taken."
  | Hierarchy => "Tree-shaped delegation with a root coordinator and sub-agents."
  | Swarm => "Decentralised self-organisation. Agents discover and coordinate autonomously."
  }
}

/// Human-readable display name for a coordination strategy.
let strategyDisplayName = (strategy: coordination): string => {
  switch strategy {
  | Solo => "Solo"
  | Pipeline => "Pipeline"
  | Broadcast => "Broadcast"
  | Consensus => "Consensus"
  | Hierarchy => "Hierarchy"
  | Swarm => "Swarm"
  }
}

/// Lucide icon name for a coordination strategy.
let strategyIcon = (strategy: coordination): string => {
  switch strategy {
  | Solo => "user"
  | Pipeline => "arrow-right"
  | Broadcast => "radio"
  | Consensus => "users"
  | Hierarchy => "git-branch"
  | Swarm => "hexagon"
  }
}

// ============================================================================
// Memory Type Helpers
// ============================================================================

/// Whether a memory type persists beyond a single session.
let memoryIsPersistent = (mem: memoryType): bool => {
  switch mem {
  | Ephemeral => false
  | Session => false
  | Persistent => true
  | Shared => true
  | Immutable => true
  }
}

/// Human-readable label for a memory type.
let memoryLabel = (mem: memoryType): string => {
  switch mem {
  | Ephemeral => "Ephemeral"
  | Session => "Session"
  | Persistent => "Persistent"
  | Shared => "Shared"
  | Immutable => "Immutable"
  }
}

/// Short icon-like character for a memory type indicator.
let memoryIndicator = (mem: memoryType): string => {
  switch mem {
  | Ephemeral => "E"
  | Session => "S"
  | Persistent => "P"
  | Shared => "H"
  | Immutable => "I"
  }
}

/// Tailwind colour class for a memory type indicator badge.
let memoryColor = (mem: memoryType): string => {
  switch mem {
  | Ephemeral => "bg-gray-600 text-gray-200"
  | Session => "bg-blue-600 text-white"
  | Persistent => "bg-emerald-600 text-white"
  | Shared => "bg-purple-600 text-white"
  | Immutable => "bg-amber-600 text-white"
  }
}

// ============================================================================
// Node State Colours
// ============================================================================

/// Tailwind text colour class for an agent node state.
let nodeStateColor = (state: agentNodeState): string => {
  switch state {
  | Active => "text-emerald-400"
  | Idle => "text-gray-400"
  | Disconnected => "text-red-400"
  | NodeError => "text-red-600"
  }
}

/// Tailwind border colour class for an agent node state.
let nodeBorderColor = (state: agentNodeState): string => {
  switch state {
  | Active => "border-emerald-500"
  | Idle => "border-gray-500"
  | Disconnected => "border-red-500"
  | NodeError => "border-red-600"
  }
}

/// Human-readable label for a node state.
let nodeStateLabel = (state: agentNodeState): string => {
  switch state {
  | Active => "Active"
  | Idle => "Idle"
  | Disconnected => "Disconnected"
  | NodeError => "Error"
  }
}

// ============================================================================
// Topology Layout
// ============================================================================

/// Suggested layout style for a coordination strategy.
/// Returns a CSS-compatible layout hint.
let topologyLayout = (strategy: coordination): string => {
  switch strategy {
  | Solo => "single"
  | Pipeline => "horizontal"
  | Broadcast => "star"
  | Consensus => "ring"
  | Hierarchy => "tree"
  | Swarm => "mesh"
  }
}

/// Tailwind border colour for a strategy card.
let strategyBorderColor = (strategy: coordination, isSelected: bool): string => {
  if isSelected {
    "border-emerald-500 ring-2 ring-emerald-500/30"
  } else {
    switch strategy {
    | Solo => "border-gray-500/40"
    | Pipeline => "border-blue-500/40"
    | Broadcast => "border-cyan-500/40"
    | Consensus => "border-purple-500/40"
    | Hierarchy => "border-amber-500/40"
    | Swarm => "border-red-500/40"
    }
  }
}

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the Agent Coordination View.
let init: agentCoordinationState = {
  nodes: [],
  edges: [],
  selectedStrategy: None,
  loading: false,
}
