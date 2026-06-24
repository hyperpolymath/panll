// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent Coordination View Panel — multi-agent topology and
/// coordination strategy display.
///
/// Layout: Strategy selector (6 cards) at top, agent topology diagram
/// below showing nodes connected by labelled edges. Memory type
/// indicators appear as badges on each agent node.

open Msg
open AgentCoordinationModel
open AgentCoordinationEngine
open Tea.Html

// ============================================================================
// Memory Type Badges
// ============================================================================

/// A small badge for a memory type indicator on an agent node.
let memoryBadge = (mem: memoryType): Tea_Vdom.t<msg> => {
  let colorClass = memoryColor(mem)
  span(
    list{Attrs.class_(`px-1 py-0.5 text-xs rounded font-mono ${colorClass}`)},
    list{text(memoryIndicator(mem))},
  )
}

// ============================================================================
// Strategy Card
// ============================================================================

/// A single strategy card in the selector grid.
let strategyCard = (strategy: coordination, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderClass = strategyBorderColor(strategy, isSelected)
  div(
    list{
      Attrs.class_(
        `flex flex-col p-3 rounded-lg border-2 cursor-pointer transition-all ${borderClass} bg-gray-900/50 hover:brightness-110`,
      ),
    },
    list{
      // Strategy name
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(
            list{Attrs.class_("font-semibold text-sm text-gray-100")},
            list{text(strategyDisplayName(strategy))},
          ),
          if isSelected {
            span(list{Attrs.class_("text-xs text-emerald-400 font-mono")}, list{text("ACTIVE")})
          } else {
            noNode
          },
        },
      ),
      // Multi-agent indicator
      if isMultiAgent(strategy) {
        span(list{Attrs.class_("text-xs text-purple-400 mb-1")}, list{text("Multi-Agent")})
      } else {
        span(list{Attrs.class_("text-xs text-gray-500 mb-1")}, list{text("Single Agent")})
      },
      // Description
      p(
        list{Attrs.class_("text-xs text-gray-400 leading-relaxed")},
        list{text(strategyDescription(strategy))},
      ),
    },
  )
}

// ============================================================================
// Agent Node
// ============================================================================

/// A single agent node in the topology diagram.
let agentNodeView = (node: agentNode): Tea_Vdom.t<msg> => {
  let stateColor = nodeStateColor(node.state)
  let borderColor = nodeBorderColor(node.state)
  div(
    list{
      Attrs.class_(
        `flex flex-col items-center p-3 rounded-lg border ${borderColor} bg-gray-900/50 min-w-32`,
      ),
    },
    list{
      // State indicator dot
      span(list{Attrs.class_(`w-2 h-2 rounded-full mb-1 ${stateColor}`)}, list{}),
      // Agent name
      span(list{Attrs.class_("text-sm font-semibold text-gray-100 mb-1")}, list{text(node.name)}),
      // State label
      span(
        list{Attrs.class_(`text-xs ${stateColor} mb-2`)},
        list{text(nodeStateLabel(node.state))},
      ),
      // Strategy badge
      span(
        list{Attrs.class_("text-xs text-gray-500 mb-2")},
        list{text(strategyDisplayName(node.strategy))},
      ),
      // Memory type badges
      div(
        list{Attrs.class_("flex gap-1 flex-wrap justify-center")},
        node.memoryTypes->Array.map(memoryBadge)->List.fromArray,
      ),
    },
  )
}

// ============================================================================
// Topology Edge
// ============================================================================

/// An edge label between two nodes (displayed as text since full SVG
/// topology rendering is deferred to a future version).
let edgeLabel = (edge: topologyEdge): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 text-xs text-gray-500")},
    list{
      span(list{Attrs.class_("font-mono")}, list{text(edge.fromId)}),
      span(list{Attrs.class_("text-gray-600")}, list{text("--" ++ edge.label ++ "-->")}),
      span(list{Attrs.class_("font-mono")}, list{text(edge.toId)}),
    },
  )
}

// ============================================================================
// Topology Diagram
// ============================================================================

/// The topology diagram showing agent nodes and their connections.
let topologyDiagram = (nodes: array<agentNode>, edges: array<topologyEdge>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col gap-4")},
    list{
      // Agent nodes (flex wrapped)
      div(
        list{Attrs.class_("flex gap-3 flex-wrap")},
        nodes->Array.map(agentNodeView)->List.fromArray,
      ),
      // Edge labels
      if Array.length(edges) > 0 {
        div(
          list{
            Attrs.class_("flex flex-col gap-1 p-3 bg-gray-900/30 rounded border border-gray-800"),
          },
          list{
            h4(
              list{Attrs.class_("text-xs font-semibold text-gray-400 mb-1")},
              list{text("Connections")},
            ),
            div(
              list{Attrs.class_("flex flex-col gap-1")},
              edges->Array.map(edgeLabel)->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Main View
// ============================================================================

/// All 6 coordination strategies for the selector grid.
let allStrategies: array<coordination> = [Solo, Pipeline, Broadcast, Consensus, Hierarchy, Swarm]

/// Top-level view for the Agent Coordination View panel.
let view = (state: agentCoordinationState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-col h-full p-3 bg-gray-950 text-gray-100")},
    list{
      // Panel header
      div(
        list{Attrs.class_("flex items-center justify-between mb-3")},
        list{
          h2(list{Attrs.class_("text-lg font-semibold")}, list{text("Agent Coordination View")}),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(Array.length(state.nodes))} agents`)},
          ),
        },
      ),
      // Strategy selector (3x2 grid)
      div(
        list{Attrs.class_("grid grid-cols-3 gap-2 mb-4")},
        allStrategies
        ->Array.map(s => strategyCard(s, state.selectedStrategy == Some(s)))
        ->List.fromArray,
      ),
      // Topology diagram
      div(
        list{Attrs.class_("flex-1 overflow-y-auto")},
        list{
          if state.loading {
            div(
              list{Attrs.class_("flex items-center justify-center h-32 text-gray-600")},
              list{text("Loading topology...")},
            )
          } else if Array.length(state.nodes) == 0 {
            div(
              list{Attrs.class_("flex items-center justify-center h-32 text-gray-600")},
              list{text("No agents registered")},
            )
          } else {
            topologyDiagram(state.nodes, state.edges)
          },
        },
      ),
    },
  )
}
