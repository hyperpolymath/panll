// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Panel Bus — cross-panel event types for inter-module communication.
///
/// When one panel's state change should trigger updates in another panel,
/// the Update loop emits bus events after the sub-updater runs. The main
/// update function inspects these events and dispatches follow-up messages.
///
/// This is a pure data layer — no side effects. Events are value types
/// that describe what happened, not what should happen next.

/// Cross-panel event that one module emits for others to consume.
type panelEvent =
  /// Hypatia completed a scan and routed findings to the fleet.
  | HypatiaFindingsRouted(string) // JSON payload of routed findings
  /// Hypatia updated neural confidence for a repo.
  | HypatiaConfidenceUpdated(string, float) // (repo, confidence)
  /// Git-private-farm repo list was refreshed.
  | FarmRepoListUpdated(int) // count of repos
  /// A repo's health status changed.
  | RepoHealthChanged(string, float) // (repo, healthScore)
  /// Gitbot-fleet dispatched a fix.
  | FleetFixDispatched(string, string) // (repo, fixRecipeId)
  /// Reposystem detected an RSR compliance change.
  | RsrComplianceChanged(string, float) // (repo, newScore)
  /// Database connection status changed.
  | DatabaseConnectionChanged(string, bool) // (dbName, connected)

/// Empty event array for sub-updaters with no cross-panel effects.
let noEvents: array<panelEvent> = []

/// Governance-originated events — emitted by the post-update governance
/// pass when contractile compliance, orbital stability, or database
/// connection state changes. These allow consumer panels (Hypatia, Fleet,
/// Reposystem) to react to cross-cutting state transitions.

/// Anti-Crash violation spike detected — governance tightened constraints.
type governanceEvent =
  /// Contractile compliance score changed (0.0–1.0).
  | ComplianceChanged(float)
  /// Orbital stability changed significantly.
  | StabilityChanged(float)
  /// Inference was halted by governance.
  | InferenceHalted(string) // reason
  /// Inference was resumed by governance.
  | InferenceResumed
  /// Humidity level was adjusted.
  | HumidityAdjusted(GovernanceModel.humidityLevel)

/// Convert a governance event to a panel event for bus routing.
let governanceToPanel = (evt: governanceEvent): panelEvent => {
  switch evt {
  | ComplianceChanged(score) => RsrComplianceChanged("contractiles", score)
  | StabilityChanged(score) => RepoHealthChanged("panll-orbit", score)
  | InferenceHalted(_) => RepoHealthChanged("panll-inference", 0.0)
  | InferenceResumed => RepoHealthChanged("panll-inference", 1.0)
  | HumidityAdjusted(_) => RepoHealthChanged("panll-humidity", 1.0)
  }
}

// ════════════════════════════════════════════════════════════════════════
// Tier 2: Pub/Sub Event Bus — topic-based subscriptions, event metadata,
// and a subscriber registry for declarative cross-panel communication.
// ════════════════════════════════════════════════════════════════════════

/// Event topic — coarse category for filtering subscriptions.
type eventTopic =
  | TopicScan         // Hypatia/panic-attack findings and scans
  | TopicHealth       // Repo and system health changes
  | TopicBuild        // Build, compile, test results
  | TopicGovernance   // Contractile compliance, stability
  | TopicDatabase     // Database connection, query, drift
  | TopicType         // TypeLL type checking results
  | TopicProtocol     // Protocol-Squisher analysis
  | TopicSecurity     // Security events, vault, secrets
  | TopicWorkflow     // Automation router, fleet dispatch
  | TopicUI           // Workspace, layout, session changes

/// Classify a panel event into its topic.
let eventTopic = (evt: panelEvent): eventTopic =>
  switch evt {
  | HypatiaFindingsRouted(_) => TopicScan
  | HypatiaConfidenceUpdated(_, _) => TopicScan
  | FarmRepoListUpdated(_) => TopicHealth
  | RepoHealthChanged(_, _) => TopicHealth
  | FleetFixDispatched(_, _) => TopicWorkflow
  | RsrComplianceChanged(_, _) => TopicGovernance
  | DatabaseConnectionChanged(_, _) => TopicDatabase
  }

/// Human-readable label for a topic.
let topicLabel = (t: eventTopic): string =>
  switch t {
  | TopicScan => "Scan"
  | TopicHealth => "Health"
  | TopicBuild => "Build"
  | TopicGovernance => "Governance"
  | TopicDatabase => "Database"
  | TopicType => "Type"
  | TopicProtocol => "Protocol"
  | TopicSecurity => "Security"
  | TopicWorkflow => "Workflow"
  | TopicUI => "UI"
  }

/// All topics for display.
let allTopics: array<eventTopic> = [
  TopicScan, TopicHealth, TopicBuild, TopicGovernance, TopicDatabase,
  TopicType, TopicProtocol, TopicSecurity, TopicWorkflow, TopicUI,
]

/// Envelope wrapping an event with metadata for tracing and debugging.
type eventEnvelope = {
  /// Unique event ID (monotonic counter).
  eventId: int,
  /// Source panel/clade that emitted the event.
  sourceCladeId: string,
  /// Topic for subscription filtering.
  topic: eventTopic,
  /// The underlying event.
  event: panelEvent,
  /// Timestamp (ms since epoch).
  timestampMs: float,
}

/// A subscriber declaration — which panel wants which topics.
type subscriber = {
  /// The clade ID of the subscribing panel.
  cladeId: string,
  /// Topics this subscriber is interested in.
  topics: array<eventTopic>,
  /// Whether this subscriber is currently active.
  active: bool,
}

/// The subscriber registry — which clades listen to which topics.
type subscriberRegistry = {
  subscribers: array<subscriber>,
  /// Monotonic event counter for envelope IDs.
  nextEventId: int,
  /// Recent event log for debugging (bounded ring buffer).
  recentEvents: array<eventEnvelope>,
  /// Max events to keep in the ring buffer.
  maxRecentEvents: int,
}

/// Default empty registry.
let emptyRegistry: subscriberRegistry = {
  subscribers: [],
  nextEventId: 1,
  recentEvents: [],
  maxRecentEvents: 100,
}

/// Default subscriber declarations for core panels.
let defaultSubscribers: array<subscriber> = [
  { cladeId: "fleet",     topics: [TopicScan, TopicHealth, TopicWorkflow],    active: true },
  { cladeId: "hypatia",   topics: [TopicScan, TopicGovernance, TopicHealth],  active: true },
  { cladeId: "databases",  topics: [TopicDatabase, TopicType],                active: true },
  { cladeId: "typell",    topics: [TopicType, TopicProtocol, TopicBuild],     active: true },
  { cladeId: "security",  topics: [TopicSecurity, TopicScan],                 active: true },
  { cladeId: "workspace", topics: [TopicUI, TopicHealth],                     active: true },
  { cladeId: "automation-router", topics: [TopicWorkflow, TopicBuild, TopicGovernance], active: true },
  { cladeId: "farm",      topics: [TopicHealth],                              active: true },
  { cladeId: "protocol-squisher", topics: [TopicProtocol, TopicType],         active: true },
  { cladeId: "my-lang",   topics: [TopicBuild, TopicType],                    active: true },
  { cladeId: "boj",       topics: [TopicProtocol, TopicDatabase, TopicWorkflow], active: true },
]

/// Default registry with core subscribers.
let defaultRegistry: subscriberRegistry = {
  ...emptyRegistry,
  subscribers: defaultSubscribers,
}

/// Register a new subscriber (or reactivate an existing one).
let subscribe = (reg: subscriberRegistry, cladeId: string, topics: array<eventTopic>): subscriberRegistry => {
  let exists = reg.subscribers->Array.some(s => s.cladeId == cladeId)
  let subscribers = if exists {
    reg.subscribers->Array.map(s =>
      if s.cladeId == cladeId {
        { ...s, topics, active: true }
      } else {
        s
      }
    )
  } else {
    Array.concat(reg.subscribers, [{ cladeId, topics, active: true }])
  }
  { ...reg, subscribers }
}

/// Unsubscribe a clade (deactivate, don't remove — preserves history).
let unsubscribe = (reg: subscriberRegistry, cladeId: string): subscriberRegistry => {
  let subscribers = reg.subscribers->Array.map(s =>
    if s.cladeId == cladeId { { ...s, active: false } } else { s }
  )
  { ...reg, subscribers }
}

/// Find all active subscribers interested in a given topic.
let subscribersForTopic = (reg: subscriberRegistry, topic: eventTopic): array<subscriber> =>
  reg.subscribers->Array.filter(s =>
    s.active && s.topics->Array.some(t => t == topic)
  )

/// Find all active subscribers interested in a given event.
let subscribersForEvent = (reg: subscriberRegistry, evt: panelEvent): array<subscriber> =>
  subscribersForTopic(reg, eventTopic(evt))

/// Wrap an event in an envelope and advance the registry counter.
let wrapEvent = (
  reg: subscriberRegistry,
  sourceCladeId: string,
  evt: panelEvent,
  nowMs: float,
): (eventEnvelope, subscriberRegistry) => {
  let envelope = {
    eventId: reg.nextEventId,
    sourceCladeId,
    topic: eventTopic(evt),
    event: evt,
    timestampMs: nowMs,
  }
  // Ring buffer: keep only maxRecentEvents.
  let recent = Array.concat(reg.recentEvents, [envelope])
  let trimmed = if Array.length(recent) > reg.maxRecentEvents {
    recent->Array.sliceToEnd(~start=Array.length(recent) - reg.maxRecentEvents)
  } else {
    recent
  }
  (envelope, { ...reg, nextEventId: reg.nextEventId + 1, recentEvents: trimmed })
}

/// Get recent events filtered by topic.
let recentByTopic = (reg: subscriberRegistry, topic: eventTopic): array<eventEnvelope> =>
  reg.recentEvents->Array.filter(e => e.topic == topic)

/// Get recent events from a specific source clade.
let recentFromClade = (reg: subscriberRegistry, cladeId: string): array<eventEnvelope> =>
  reg.recentEvents->Array.filter(e => e.sourceCladeId == cladeId)

/// Count active subscribers.
let activeSubscriberCount = (reg: subscriberRegistry): int =>
  reg.subscribers->Array.filter(s => s.active)->Array.length

/// Count total events processed.
let totalEventsProcessed = (reg: subscriberRegistry): int =>
  reg.nextEventId - 1
