// SPDX-License-Identifier: MPL-2.0

/// ProofChain — CI/CD-style visual proof pipeline.
///
/// Transforms an ECHIDNA interactive proof session into a GitHub Actions–like
/// pipeline view. Each node is a proof step (goal or tactic application) with
/// status indicators (green/amber/red), connectors showing dependencies, and
/// dashed outlines for detected gaps.
///
/// Visual language:
///   ● Green (discharged)  — goal solved, tactic succeeded
///   ◐ Amber (in progress) — goal exists, work underway
///   ○ Red (failed/stuck)  — tactic didn't close, error
///   ╌ Dashed (gap)        — missing step detected by constraint propagation
///
/// The pipeline reads top-to-bottom: root goal → tactic applications → subgoals.
/// Branching occurs when a tactic (e.g., induction) produces multiple subgoals.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Proof Chain Node Types
// ===========================================================================

/// The status of a node in the proof pipeline.
type nodeStatus =
  | Discharged // Goal solved — all green
  | Active // Currently being worked on
  | Pending // Exists but no tactic applied yet
  | Failed // Tactic failed or goal stuck
  | Gap // Missing step detected

/// The type of a node in the proof pipeline.
type nodeType =
  | GoalNode // A proof obligation / goal
  | TacticNode // A tactic application
  | QedNode // Final QED / proof complete marker

/// A single node in the proof pipeline graph.
type pipelineNode = {
  id: string,
  label: string,
  detail: string,
  status: nodeStatus,
  nodeType: nodeType,
  children: array<string>, // IDs of child nodes
}

/// The full pipeline graph.
type pipelineGraph = {
  nodes: array<pipelineNode>,
  rootId: string,
}

// ===========================================================================
// Session → Pipeline Graph Conversion
// ===========================================================================

/// Build a pipeline graph from an ECHIDNA session state.
/// The graph structure:
///   Root Goal → [Tactic 1] → [Subgoal A, Subgoal B, ...]
///                            → [Tactic 2] → [Subgoal C, ...]
///                            → QED (if complete)
let buildGraph = (session: echidnaSessionState): pipelineGraph => {
  let nodes: array<pipelineNode> = []

  // Root goal node
  let rootId = "goal-root"
  let rootStatus = if session.complete {
    Discharged
  } else if Array.length(session.goals) === 0 {
    Discharged
  } else {
    Active
  }

  let rootNode = {
    id: rootId,
    label: "Goal",
    detail: session.goal,
    status: rootStatus,
    nodeType: GoalNode,
    children: [],
  }
  let _ = Array.push(nodes, rootNode)

  // Build tactic chain
  let prevNodeId = ref(rootId)

  session.proofScript->Array.forEachWithIndex((tactic, idx) => {
    let tacticId = "tactic-" ++ Int.toString(idx)

    // Determine tactic status
    let tacticStatus = if session.complete || idx < Array.length(session.proofScript) - 1 {
      Discharged // Past tactics are resolved
    } else {
      // Last tactic — check session status
      switch session.status {
      | ProofSuccess => Discharged
      | InProgress => Active
      | ProofFailed => Failed
      | ProofError => Failed
      | ProofTimeout => Failed
      | Pending => Pending
      }
    }

    let tacticNode = {
      id: tacticId,
      label: tactic,
      detail: "Step " ++ Int.toString(idx + 1),
      status: tacticStatus,
      nodeType: TacticNode,
      children: [],
    }
    let _ = Array.push(nodes, tacticNode)

    // Link previous node to this tactic
    nodes->Array.forEach(n => {
      if n.id === prevNodeId.contents {
        let _ = Array.push(n.children, tacticId)
      }
    })

    prevNodeId := tacticId
  })

  // Add remaining goals as pending subgoals off the last tactic
  session.goals->Array.forEachWithIndex((goal, idx) => {
    let goalId = "subgoal-" ++ Int.toString(idx)
    let goalStatus = if idx === 0 {
      Active
    } else {
      Pending
    }

    let goalNode = {
      id: goalId,
      label: "Subgoal " ++ Int.toString(idx + 1),
      detail: goal,
      status: goalStatus,
      nodeType: GoalNode,
      children: [],
    }
    let _ = Array.push(nodes, goalNode)

    // Link from last tactic (or root if no tactics applied)
    nodes->Array.forEach(n => {
      if n.id === prevNodeId.contents {
        let _ = Array.push(n.children, goalId)
      }
    })
  })

  // If proof is complete, add QED node
  if session.complete {
    let qedId = "qed"
    let qedNode = {
      id: qedId,
      label: "QED",
      detail: "Proof complete",
      status: Discharged,
      nodeType: QedNode,
      children: [],
    }
    let _ = Array.push(nodes, qedNode)

    // Link from last node
    nodes->Array.forEach(n => {
      if n.id === prevNodeId.contents {
        let _ = Array.push(n.children, qedId)
      }
    })
  }

  // Detect gaps: if there are remaining goals but no tactic suggestions,
  // add gap nodes to signal missing steps
  if !session.complete && Array.length(session.goals) > 0 && Array.length(session.proofScript) > 0 {
    session.goals->Array.forEachWithIndex((_, idx) => {
      let subgoalId = "subgoal-" ++ Int.toString(idx)
      let gapId = "gap-" ++ Int.toString(idx)
      let gapNode = {
        id: gapId,
        label: "?",
        detail: "Missing tactic — apply a step to close this goal",
        status: Gap,
        nodeType: TacticNode,
        children: [],
      }
      let _ = Array.push(nodes, gapNode)

      // Link from the subgoal to the gap
      nodes->Array.forEach(n => {
        if n.id === subgoalId {
          let _ = Array.push(n.children, gapId)
        }
      })
    })
  }

  {nodes, rootId}
}

// ===========================================================================
// Pipeline Rendering
// ===========================================================================

/// Status colour classes for node badges.
let statusClasses = (status: nodeStatus): (string, string, string) => {
  // (border, bg, text)
  switch status {
  | Discharged => ("border-green-500", "bg-green-900/40", "text-green-400")
  | Active => ("border-blue-500", "bg-blue-900/40", "text-blue-400")
  | Pending => ("border-amber-500", "bg-amber-900/30", "text-amber-400")
  | Failed => ("border-red-500", "bg-red-900/40", "text-red-400")
  | Gap => ("border-gray-500 border-dashed", "bg-gray-800/30", "text-gray-500")
  }
}

/// Status icon character.
let statusIcon = (status: nodeStatus): string => {
  switch status {
  | Discharged => `\u2713` // ✓
  | Active => `\u25D0` // ◐
  | Pending => `\u25CB` // ○
  | Failed => `\u2717` // ✗
  | Gap => "?"
  }
}

/// Status label text.
let statusLabel = (status: nodeStatus): string => {
  switch status {
  | Discharged => "Discharged"
  | Active => "In progress"
  | Pending => "Pending"
  | Failed => "Failed"
  | Gap => "Gap detected"
  }
}

/// Node type icon.
let nodeTypeIcon = (nt: nodeType): string => {
  switch nt {
  | GoalNode => `\u25A0` // ■
  | TacticNode => `\u25B6` // ▶
  | QedNode => `\u2605` // ★
  }
}

/// Render a vertical connector line between pipeline stages.
let renderConnector = (status: nodeStatus): Tea_Vdom.t<msg> => {
  let (_, _, textColour) = statusClasses(status)
  let lineStyle = switch status {
  | Gap => "border-l border-dashed border-gray-600"
  | _ => "border-l border-gray-600"
  }
  div(
    list{Attrs.class_("flex justify-center py-0")},
    list{
      div(list{Attrs.class_(`h-4 w-0 ml-4 ${lineStyle}`), Attrs.ariaHidden(true)}, list{}),
      div(list{Attrs.class_(`text-[8px] ${textColour} ml-1 self-center`)}, list{text({`\u25BC`})}), // ▼
    },
  )
}

/// Render a single pipeline node.
let renderNode = (node: pipelineNode): Tea_Vdom.t<msg> => {
  let (borderClass, bgClass, textClass) = statusClasses(node.status)
  let icon = statusIcon(node.status)
  let typeIcon = nodeTypeIcon(node.nodeType)

  div(
    list{
      Attrs.class_(`flex items-start gap-2 p-2 rounded-lg border ${borderClass} ${bgClass} mx-1`),
      Attrs.title(node.detail),
      Attrs.ariaLabel(node.label ++ " — " ++ statusLabel(node.status)),
    },
    list{
      // Status icon
      div(
        list{Attrs.class_(`text-sm ${textClass} w-5 text-center flex-shrink-0 mt-0.5`)},
        list{text(icon)},
      ),
      // Content
      div(
        list{Attrs.class_("flex-1 min-w-0")},
        list{
          // Header row: type icon + label + status badge
          div(
            list{Attrs.class_("flex items-center gap-1.5")},
            list{
              span(list{Attrs.class_(`text-[10px] ${textClass}`)}, list{text(typeIcon)}),
              span(list{Attrs.class_(`text-xs font-bold ${textClass}`)}, list{text(node.label)}),
              span(
                list{
                  Attrs.class_(
                    `text-[10px] px-1.5 py-0 rounded ${bgClass} ${textClass} border ${borderClass} ml-auto`,
                  ),
                },
                list{text(statusLabel(node.status))},
              ),
            },
          ),
          // Detail (truncated)
          if node.detail !== "" && node.detail !== node.label {
            div(
              list{Attrs.class_("text-[11px] text-gray-400 font-mono truncate mt-0.5")},
              list{text(node.detail)},
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}

/// Render a branch — a node and all its children recursively.
let rec renderBranch = (graph: pipelineGraph, nodeId: string, depth: int): Tea_Vdom.t<msg> => {
  let maybeNode = graph.nodes->Array.find(n => n.id === nodeId)
  switch maybeNode {
  | None => noNode
  | Some(node) =>
    div(
      list{Attrs.class_("flex flex-col")},
      list{
        renderNode(node),
        // Children
        if Array.length(node.children) === 0 {
          noNode
        } else if Array.length(node.children) === 1 {
          // Single child — straight connector
          let childId = node.children[0]->Option.getOr("")
          let childNode = graph.nodes->Array.find(n => n.id === childId)
          let childStatus = switch childNode {
          | Some(cn) => cn.status
          | None => Pending
          }
          div(list{}, list{renderConnector(childStatus), renderBranch(graph, childId, depth + 1)})
        } else {
          // Multiple children — branching pipeline
          div(
            list{Attrs.class_("mt-1")},
            list{
              // Branch indicator
              div(
                list{Attrs.class_("flex items-center gap-1 ml-4 mb-1")},
                list{
                  div(list{Attrs.class_("h-px flex-1 bg-gray-600")}, list{}),
                  span(
                    list{Attrs.class_("text-[9px] text-gray-500 px-1")},
                    list{text(Int.toString(Array.length(node.children)) ++ " branches")},
                  ),
                  div(list{Attrs.class_("h-px flex-1 bg-gray-600")}, list{}),
                },
              ),
              // Render each branch
              div(
                list{Attrs.class_("grid gap-1 pl-3 border-l border-gray-700")},
                node.children
                ->Array.map(childId => renderBranch(graph, childId, depth + 1))
                ->List.fromArray,
              ),
            },
          )
        },
      },
    )
  }
}

// ===========================================================================
// Summary Stats
// ===========================================================================

/// Count nodes by status in the pipeline.
let countByStatus = (graph: pipelineGraph, status: nodeStatus): int => {
  graph.nodes->Array.filter(n => n.status === status)->Array.length
}

/// Render pipeline summary stats — a compact status bar.
let renderSummaryStats = (graph: pipelineGraph): Tea_Vdom.t<msg> => {
  let discharged = countByStatus(graph, Discharged)
  let active = countByStatus(graph, Active)
  let pending = countByStatus(graph, Pending)
  let failed = countByStatus(graph, Failed)
  let gaps = countByStatus(graph, Gap)
  let total = Array.length(graph.nodes)

  // Progress percentage (discharged / total non-gap nodes)
  let nonGapTotal = total - gaps
  let progressPct = if nonGapTotal > 0 {
    Int.toString(Int.fromFloat(Int.toFloat(discharged) /. Int.toFloat(nonGapTotal) *. 100.0))
  } else {
    "0"
  }

  div(
    list{Attrs.class_("flex items-center gap-3 text-[10px] mb-2 px-1")},
    list{
      // Progress bar
      div(
        list{
          Attrs.class_("flex-1 h-1.5 bg-gray-800 rounded-full overflow-hidden"),
          Attrs.role("progressbar"),
          Attrs.ariaLabel("Proof progress"),
          Attrs.ariaValueNow(Int.toFloat(discharged)),
          Attrs.ariaValueMax(Int.toFloat(nonGapTotal)),
        },
        list{
          div(
            list{
              Attrs.class_("h-full bg-green-500 transition-all duration-300"),
              Attrs.style("width", progressPct ++ "%"),
            },
            list{},
          ),
        },
      ),
      span(list{Attrs.class_("text-gray-400")}, list{text(progressPct ++ "%")}),
      // Status counts
      if discharged > 0 {
        span(
          list{Attrs.class_("text-green-400")},
          list{text({`\u2713`} ++ Int.toString(discharged))},
        )
      } else {
        noNode
      },
      if active > 0 {
        span(list{Attrs.class_("text-blue-400")}, list{text({`\u25D0`} ++ Int.toString(active))})
      } else {
        noNode
      },
      if pending > 0 {
        span(list{Attrs.class_("text-amber-400")}, list{text({`\u25CB`} ++ Int.toString(pending))})
      } else {
        noNode
      },
      if failed > 0 {
        span(list{Attrs.class_("text-red-400")}, list{text({`\u2717`} ++ Int.toString(failed))})
      } else {
        noNode
      },
      if gaps > 0 {
        span(list{Attrs.class_("text-gray-500")}, list{text("?" ++ Int.toString(gaps))})
      } else {
        noNode
      },
    },
  )
}

// ===========================================================================
// Public API
// ===========================================================================

/// Render the full proof chain pipeline for an ECHIDNA session.
/// This is the CI/CD-style visual proof view.
let view = (session: echidnaSessionState): Tea_Vdom.t<msg> => {
  let graph = buildGraph(session)

  div(
    list{
      Attrs.class_("mt-3 p-3 bg-gray-850/50 rounded-lg border border-indigo-700/30"),
      Attrs.role("region"),
      Attrs.ariaLabel("Proof Pipeline"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{Attrs.class_("text-xs font-bold text-indigo-400 uppercase tracking-wider")},
                list{text("Proof Pipeline")},
              ),
              span(
                list{Attrs.class_("text-[10px] text-gray-500")},
                list{text(Int.toString(Array.length(graph.nodes)) ++ " nodes")},
              ),
            },
          ),
          // Legend
          div(
            list{Attrs.class_("flex items-center gap-2 text-[9px]")},
            list{
              span(list{Attrs.class_("text-green-400")}, list{text({`\u2713`} ++ " done")}),
              span(list{Attrs.class_("text-blue-400")}, list{text({`\u25D0`} ++ " active")}),
              span(list{Attrs.class_("text-amber-400")}, list{text({`\u25CB`} ++ " pending")}),
              span(list{Attrs.class_("text-red-400")}, list{text({`\u2717`} ++ " failed")}),
              span(list{Attrs.class_("text-gray-500")}, list{text("? gap")}),
            },
          ),
        },
      ),
      // Summary stats bar
      renderSummaryStats(graph),
      // Pipeline graph
      div(
        list{
          Attrs.class_("max-h-64 overflow-y-auto pr-1"),
          Attrs.role("tree"),
          Attrs.ariaLabel("Proof pipeline tree"),
        },
        list{renderBranch(graph, graph.rootId, 0)},
      ),
    },
  )
}

/// Render a compact inline proof status for use outside the ECHIDNA panel.
/// Shows a single-line summary: "3/5 goals ✓ 60%" with a tiny progress bar.
let viewCompact = (session: echidnaSessionState): Tea_Vdom.t<msg> => {
  let graph = buildGraph(session)
  let discharged = countByStatus(graph, Discharged)
  let total = Array.length(graph.nodes) - countByStatus(graph, Gap)
  let pct = if total > 0 {
    Int.toString(Int.fromFloat(Int.toFloat(discharged) /. Int.toFloat(total) *. 100.0))
  } else {
    "0"
  }

  div(
    list{Attrs.class_("flex items-center gap-2 text-xs")},
    list{
      span(list{Attrs.class_("text-indigo-400 font-bold")}, list{text("Proof")}),
      div(
        list{
          Attrs.class_("w-16 h-1 bg-gray-800 rounded-full overflow-hidden"),
          Attrs.role("progressbar"),
          Attrs.ariaLabel("Proof progress"),
        },
        list{
          div(list{Attrs.class_("h-full bg-green-500"), Attrs.style("width", pct ++ "%")}, list{}),
        },
      ),
      span(
        list{Attrs.class_("text-gray-400")},
        list{text(Int.toString(discharged) ++ "/" ++ Int.toString(total) ++ " " ++ pct ++ "%")},
      ),
    },
  )
}
