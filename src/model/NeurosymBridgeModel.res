// SPDX-License-Identifier: MPL-2.0

/// PanLL Neurosym Bridge Model — connects ECHIDNA neurosymbolic reasoning to
/// IDApTIK game development. Bridges formal verification with guard AI
/// behaviour design, patrol pattern reasoning, and behaviour tree construction.
///
/// Three-panel model (L/N/W):
///   L: Guard behaviour rules, patrol patterns, AI constraints
///   N: ECHIDNA reasoning about guard AI correctness and coverage
///   W: Behaviour tree visualisation with live simulation
///
/// Dependency: leaf module — no imports from other PanLL models.

// ============================================================================
// Tab Navigation
// ============================================================================

/// Category tabs for the Neurosym Bridge panel.
type neurosymBridgeTab =
  /// Rules — define and browse guard behaviour rules.
  | Rules
  /// BehaviourTree — visual behaviour tree editor and viewer.
  | BehaviourTree
  /// Simulation — run guard AI simulations with ECHIDNA analysis.
  | Simulation
  /// Analysis — ECHIDNA reasoning results about guard AI correctness.
  | Analysis

// ============================================================================
// Guard Behaviour Rules
// ============================================================================

/// Priority level for a guard behaviour rule.
type rulePriority =
  /// Critical — this rule must never be violated (hard constraint).
  | PriorityCritical
  /// High — important for correct guard behaviour.
  | PriorityHigh
  /// Normal — standard behaviour rule.
  | PriorityNormal
  /// Low — soft preference, may be overridden.
  | PriorityLow

/// Status of a guard behaviour rule after ECHIDNA analysis.
type ruleStatus =
  /// Verified — ECHIDNA has proven this rule is always satisfied.
  | RuleVerified
  /// Unverified — rule has not been checked yet.
  | RuleUnverified
  /// Violated — ECHIDNA found a counterexample.
  | RuleViolated
  /// Conflict — this rule contradicts another rule.
  | RuleConflict

/// A guard behaviour rule defining expected AI behaviour.
type guardRule = {
  /// Unique rule identifier.
  id: string,
  /// Human-readable rule name (e.g., "GuardsPatrolWhenIdle").
  name: string,
  /// Formal condition expression (evaluated by ECHIDNA).
  condition: string,
  /// Expected action when condition is met.
  expectedAction: string,
  /// Priority of this rule.
  priority: rulePriority,
  /// Verification status from ECHIDNA.
  status: ruleStatus,
  /// Human-readable description.
  description: string,
}

// ============================================================================
// Behaviour Tree Nodes
// ============================================================================

/// Type of a behaviour tree node.
type behaviourNodeType =
  /// Sequence — runs children in order, fails on first failure.
  | NodeSequence
  /// Selector — tries children in order, succeeds on first success.
  | NodeSelector
  /// Parallel — runs children concurrently.
  | NodeParallel
  /// Decorator — wraps a single child with a modifier (invert, repeat, etc.).
  | NodeDecorator
  /// Action — leaf node that performs a game action.
  | NodeAction
  /// Condition — leaf node that checks a predicate.
  | NodeCondition

/// A single node in the guard behaviour tree.
type behaviourNode = {
  /// Unique node identifier.
  id: string,
  /// Node type (sequence, selector, action, condition, etc.).
  nodeType: behaviourNodeType,
  /// Display label for this node.
  label: string,
  /// Child node identifiers (empty for leaf nodes).
  children: array<string>,
  /// Condition expression (for condition and decorator nodes).
  condition: option<string>,
  /// Action identifier (for action leaf nodes).
  action: option<string>,
}

// ============================================================================
// Simulation Results
// ============================================================================

/// Outcome of a single guard AI simulation step.
type simulationStepOutcome =
  /// Guard performed the expected action.
  | StepSuccess
  /// Guard performed an unexpected action.
  | StepDeviation
  /// Guard entered a deadlock or infinite loop.
  | StepDeadlock

/// A single step in a guard AI simulation run.
type simulationStep = {
  /// Step number (1-based).
  stepNumber: int,
  /// Guard state at this step (serialised).
  guardState: string,
  /// Action taken by the guard AI.
  actionTaken: string,
  /// Outcome of this step.
  outcome: simulationStepOutcome,
  /// Elapsed simulation time in milliseconds.
  elapsedMs: float,
}

/// Complete simulation result for a guard AI run.
type neurosymSimulationResult = {
  /// Total number of steps executed.
  totalSteps: int,
  /// Steps that deviated from expected behaviour.
  deviations: int,
  /// Whether the simulation completed without deadlock.
  completed: bool,
  /// Individual simulation steps.
  steps: array<simulationStep>,
  /// ECHIDNA analysis summary of the simulation.
  analysisSummary: string,
}

// ============================================================================
// Panel State
// ============================================================================

/// Root state for the Neurosym Bridge panel.
type neurosymBridgeState = {
  /// Active tab within the Neurosym Bridge panel.
  activeTab: neurosymBridgeTab,
  /// All registered guard behaviour rules.
  guardRules: array<guardRule>,
  /// Behaviour tree nodes for the current guard template.
  behaviourNodes: array<behaviourNode>,
  /// Results from the most recent simulation run.
  simulationResults: option<neurosymSimulationResult>,
  /// Currently selected guard identifier for detail view.
  selectedGuard: option<string>,
  /// Whether a simulation is currently running.
  simulating: bool,
  /// Error from the last operation.
  error: option<string>,
}
