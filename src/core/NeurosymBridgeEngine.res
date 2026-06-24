// SPDX-License-Identifier: MPL-2.0

/// PanLL Neurosym Bridge Engine — pure computation and helpers for the
/// Neurosym Bridge panel. Provides default state, tab metadata, rule and
/// behaviour node counting, and simulation status formatting.

open NeurosymBridgeModel

/// Default state for the Neurosym Bridge panel.
/// Starts on the Rules tab with empty rule and behaviour tree lists.
let defaultState: neurosymBridgeState = {
  activeTab: Rules,
  guardRules: [],
  behaviourNodes: [],
  simulationResults: None,
  selectedGuard: None,
  simulating: false,
  error: None,
}

/// Human-readable label for each tab in the Neurosym Bridge panel.
let tabLabel = (tab: neurosymBridgeTab): string =>
  switch tab {
  | Rules => "Rules"
  | BehaviourTree => "Behaviour Tree"
  | Simulation => "Simulation"
  | Analysis => "Analysis"
  }

/// All tabs in display order.
let allTabs: array<neurosymBridgeTab> = [Rules, BehaviourTree, Simulation, Analysis]

/// Count the total number of guard behaviour rules.
let countRules = (state: neurosymBridgeState): int => Array.length(state.guardRules)

/// Count rules by verification status.
let countRulesByStatus = (rules: array<guardRule>, status: ruleStatus): int =>
  rules->Array.filter(r => r.status === status)->Array.length

/// Count the total number of behaviour tree nodes.
let countBehaviourNodes = (state: neurosymBridgeState): int => Array.length(state.behaviourNodes)

/// Count behaviour tree leaf nodes (actions and conditions).
let countLeafNodes = (nodes: array<behaviourNode>): int =>
  nodes
  ->Array.filter(n =>
    switch n.nodeType {
    | NodeAction | NodeCondition => true
    | _ => false
    }
  )
  ->Array.length

/// Human-readable label for a rule status.
let ruleStatusLabel = (status: ruleStatus): string =>
  switch status {
  | RuleVerified => "Verified"
  | RuleUnverified => "Unverified"
  | RuleViolated => "Violated"
  | RuleConflict => "Conflict"
  }

/// Human-readable label for a behaviour node type.
let nodeTypeLabel = (nodeType: behaviourNodeType): string =>
  switch nodeType {
  | NodeSequence => "Sequence"
  | NodeSelector => "Selector"
  | NodeParallel => "Parallel"
  | NodeDecorator => "Decorator"
  | NodeAction => "Action"
  | NodeCondition => "Condition"
  }

/// Format simulation status as a human-readable summary.
/// Returns "No simulation" when no results are available.
let simulationStatus = (state: neurosymBridgeState): string =>
  switch state.simulationResults {
  | None => "No simulation"
  | Some(result) =>
    if result.completed {
      let devRate = if result.totalSteps > 0 {
        Int.toFloat(result.deviations) /. Int.toFloat(result.totalSteps) *. 100.0
      } else {
        0.0
      }
      `Completed: ${Int.toString(result.totalSteps)} steps, ${Float.toFixed(
          devRate,
          ~digits=1,
        )}% deviation`
    } else {
      `Incomplete: ${Int.toString(result.totalSteps)} steps (deadlock or timeout)`
    }
  }
