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
  /// UMS level validation completed — 5 ABI proof results.
  | UmsValidationCompleted(bool) // allPassed
  /// Level Architect entity count changed.
  | LevelArchitectEntitiesChanged(int) // entityCount
  /// UMS project opened or created.
  | UmsProjectChanged(string) // projectId
  // ── Game Testing Events ──────────────────────────────────────────────
  /// A test suite completed execution (suiteName, passCount, failCount).
  | TestSuiteCompleted(string, int, int)
  /// Balance simulation finished (simulationId, equilibriumScore).
  | BalanceSimulationDone(string, float)
  /// Player/tester feedback received (feedbackId, sentiment 0.0–1.0).
  | FeedbackReceived(string, float)
  /// Soak test detected a memory leak (processName, leakBytes).
  | SoakLeakDetected(string, int)
  /// Compatibility check completed (platformId, passed).
  | CompatibilityCheckDone(string, bool)
  /// Procedural generator produced a world (worldId, seed).
  | GeneratorWorldReady(string, int)
  /// Level Architect saved a level (levelId, entityCount).
  | ArchitectLevelSaved(string, int)
  /// Burble voice session started (panelContext, roomId).
  | BurbleVoiceStarted(string, string)
  /// Burble voice session ended (panelContext).
  | BurbleVoiceEnded(string)
  /// Burble participant started speaking (userId, displayName).
  | BurbleSpeechStarted(string, string)
  /// Burble participant stopped speaking (userId).
  | BurbleSpeechEnded(string)
  /// Burble voice tag created from speech (transcript, tagType).
  | BurbleVoiceTagCreated(string, string)

/// Empty event array for sub-updaters with no cross-panel effects.
let noEvents: array<panelEvent> = []

// ════════════════════════════════════════════════════════════════════════
// Backpressure and Scaling — strategies for handling event volume spikes.
// ════════════════════════════════════════════════════════════════════════

/// Strategy for handling ring buffer overflow under high event volume.
type backpressureStrategy =
  /// Drop the oldest events to make room (default, preserves liveness).
  | DropOldest
  /// Drop the newest events (preserves history, risks stale state).
  | DropNewest
  /// Block the emitter until space is available (use with caution).
  | Block
  /// Sample every Nth event, discarding the rest (load shedding).
  | Sample(int)

/// Subscriber dispatch priority — determines processing order.
type subscriberPriority =
  /// Dispatched first, never dropped under backpressure.
  | Critical
  /// Standard dispatch order.
  | Normal
  /// Dispatched last, may be deferred or dropped under load.
  | Background

/// Configuration record for the event bus.
type busConfig = {
  /// Maximum events retained in the ring buffer.
  maxEvents: int,
  /// Strategy when the ring buffer is full.
  backpressure: backpressureStrategy,
  /// Time-to-live for events in milliseconds (0 = no expiry).
  eventTtlMs: float,
}

/// Default bus configuration — 500-event ring buffer, drop-oldest, no TTL.
let defaultBusConfig: busConfig = {
  maxEvents: 500,
  backpressure: DropOldest,
  eventTtlMs: 0.0,
}

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
  | HumidityAdjusted(PaneModel.humidityLevel)

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
  | TopicScan // Hypatia/panic-attack findings and scans
  | TopicHealth // Repo and system health changes
  | TopicBuild // Build, compile, test results
  | TopicGovernance // Contractile compliance, stability
  | TopicDatabase // Database connection, query, drift
  | TopicType // TypeLL type checking results
  | TopicProtocol // Protocol-Squisher analysis
  | TopicSecurity // Security events, vault, secrets
  | TopicWorkflow // Automation router, fleet dispatch
  | TopicUI // Workspace, layout, session changes
  | TopicTesting // Game testing: unit, functional, soak, compat
  | TopicSimulation // Balance simulation, procedural generation

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
  | UmsValidationCompleted(_) => TopicBuild
  | LevelArchitectEntitiesChanged(_) => TopicUI
  | UmsProjectChanged(_) => TopicWorkflow
  | TestSuiteCompleted(_, _, _) => TopicTesting
  | FeedbackReceived(_, _) => TopicTesting
  | SoakLeakDetected(_, _) => TopicTesting
  | CompatibilityCheckDone(_, _) => TopicTesting
  | BalanceSimulationDone(_, _) => TopicSimulation
  | GeneratorWorldReady(_, _) => TopicSimulation
  | ArchitectLevelSaved(_, _) => TopicUI
  | BurbleVoiceStarted(_, _) => TopicUI
  | BurbleVoiceEnded(_) => TopicUI
  | BurbleSpeechStarted(_, _) => TopicUI
  | BurbleSpeechEnded(_) => TopicUI
  | BurbleVoiceTagCreated(_, _) => TopicUI
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
  | TopicTesting => "Testing"
  | TopicSimulation => "Simulation"
  }

/// All topics for display.
let allTopics: array<eventTopic> = [
  TopicScan,
  TopicHealth,
  TopicBuild,
  TopicGovernance,
  TopicDatabase,
  TopicType,
  TopicProtocol,
  TopicSecurity,
  TopicWorkflow,
  TopicUI,
  TopicTesting,
  TopicSimulation,
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
  /// Dispatch priority — Critical subscribers are dispatched first.
  priority: subscriberPriority,
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
  maxRecentEvents: 500,
}

/// Default subscriber declarations for core panels.
let defaultSubscribers: array<subscriber> = [
  // ── Core infrastructure panels ───────────────────────────────────────
  {
    cladeId: "fleet",
    topics: [TopicScan, TopicHealth, TopicWorkflow],
    active: true,
    priority: Critical,
  },
  {
    cladeId: "hypatia",
    topics: [TopicScan, TopicGovernance, TopicHealth],
    active: true,
    priority: Critical,
  },
  {cladeId: "databases", topics: [TopicDatabase, TopicType], active: true, priority: Normal},
  {
    cladeId: "vcl",
    topics: [TopicDatabase, TopicType, TopicProtocol],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "typell",
    topics: [TopicType, TopicProtocol, TopicBuild],
    active: true,
    priority: Normal,
  },
  {cladeId: "security", topics: [TopicSecurity, TopicScan], active: true, priority: Critical},
  {cladeId: "workspace", topics: [TopicUI, TopicHealth], active: true, priority: Normal},
  {
    cladeId: "automation-router",
    topics: [TopicWorkflow, TopicBuild, TopicGovernance],
    active: true,
    priority: Normal,
  },
  {cladeId: "farm", topics: [TopicHealth], active: true, priority: Background},
  {
    cladeId: "protocol-squisher",
    topics: [TopicProtocol, TopicType],
    active: true,
    priority: Normal,
  },
  {cladeId: "my-lang", topics: [TopicBuild, TopicType], active: true, priority: Normal},
  {
    cladeId: "boj",
    topics: [TopicProtocol, TopicDatabase, TopicWorkflow],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "ums",
    topics: [TopicBuild, TopicUI, TopicWorkflow, TopicType],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "level-architect",
    topics: [TopicBuild, TopicUI, TopicType],
    active: true,
    priority: Normal,
  },
  // ── Game dev testing panels (24 new panels) ──────────────────────────
  {cladeId: "unit-test-runner", topics: [TopicTesting, TopicBuild], active: true, priority: Normal},
  {
    cladeId: "functional-tester",
    topics: [TopicTesting, TopicBuild],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "integration-tester",
    topics: [TopicTesting, TopicBuild],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "regression-tester",
    topics: [TopicTesting, TopicBuild],
    active: true,
    priority: Normal,
  },
  {
    cladeId: "performance-profiler",
    topics: [TopicTesting, TopicHealth],
    active: true,
    priority: Normal,
  },
  {cladeId: "soak-tester", topics: [TopicTesting, TopicHealth], active: true, priority: Normal},
  {cladeId: "stress-tester", topics: [TopicTesting, TopicHealth], active: true, priority: Normal},
  {cladeId: "fuzz-tester", topics: [TopicTesting, TopicSecurity], active: true, priority: Normal},
  {cladeId: "compatibility-checker", topics: [TopicTesting], active: true, priority: Background},
  {
    cladeId: "accessibility-checker",
    topics: [TopicTesting, TopicUI],
    active: true,
    priority: Background,
  },
  {
    cladeId: "localisation-checker",
    topics: [TopicTesting, TopicUI],
    active: true,
    priority: Background,
  },
  {
    cladeId: "balance-simulator",
    topics: [TopicSimulation, TopicTesting],
    active: true,
    priority: Normal,
  },
  {cladeId: "economy-simulator", topics: [TopicSimulation], active: true, priority: Normal},
  {
    cladeId: "ai-behaviour-tester",
    topics: [TopicSimulation, TopicTesting],
    active: true,
    priority: Normal,
  },
  {cladeId: "world-generator", topics: [TopicSimulation, TopicUI], active: true, priority: Normal},
  {
    cladeId: "replay-analyser",
    topics: [TopicTesting, TopicWorkflow],
    active: true,
    priority: Background,
  },
  {
    cladeId: "feedback-collector",
    topics: [TopicTesting, TopicUI],
    active: true,
    priority: Background,
  },
  {
    cladeId: "crash-reporter",
    topics: [TopicTesting, TopicHealth, TopicSecurity],
    active: true,
    priority: Critical,
  },
  {cladeId: "network-tester", topics: [TopicTesting, TopicHealth], active: true, priority: Normal},
  {
    cladeId: "save-load-tester",
    topics: [TopicTesting, TopicDatabase],
    active: true,
    priority: Normal,
  },
  {cladeId: "input-tester", topics: [TopicTesting, TopicUI], active: true, priority: Normal},
  {cladeId: "audio-tester", topics: [TopicTesting], active: true, priority: Background},
  {cladeId: "visual-diff-tester", topics: [TopicTesting, TopicUI], active: true, priority: Normal},
  {cladeId: "memory-profiler", topics: [TopicTesting, TopicHealth], active: true, priority: Normal},
]

/// Default registry with core subscribers.
let defaultRegistry: subscriberRegistry = {
  ...emptyRegistry,
  subscribers: defaultSubscribers,
}

/// Register a new subscriber (or reactivate an existing one).
let subscribe = (
  reg: subscriberRegistry,
  cladeId: string,
  topics: array<eventTopic>,
): subscriberRegistry => {
  let exists = reg.subscribers->Array.some(s => s.cladeId == cladeId)
  let subscribers = if exists {
    reg.subscribers->Array.map(s =>
      if s.cladeId == cladeId {
        {...s, topics, active: true}
      } else {
        s
      }
    )
  } else {
    Array.concat(reg.subscribers, [{cladeId, topics, active: true, priority: Normal}])
  }
  {...reg, subscribers}
}

/// Unsubscribe a clade (deactivate, don't remove — preserves history).
let unsubscribe = (reg: subscriberRegistry, cladeId: string): subscriberRegistry => {
  let subscribers = reg.subscribers->Array.map(s =>
    if s.cladeId == cladeId {
      {...s, active: false}
    } else {
      s
    }
  )
  {...reg, subscribers}
}

/// Find all active subscribers interested in a given topic.
let subscribersForTopic = (reg: subscriberRegistry, topic: eventTopic): array<subscriber> =>
  reg.subscribers->Array.filter(s => s.active && s.topics->Array.some(t => t == topic))

/// Find all active subscribers interested in a given event.
let subscribersForEvent = (reg: subscriberRegistry, evt: panelEvent): array<subscriber> =>
  subscribersForTopic(reg, eventTopic(evt))

/// Wrap an event in an envelope and advance the registry counter.
let wrapEvent = (reg: subscriberRegistry, sourceCladeId: string, evt: panelEvent, nowMs: float): (
  eventEnvelope,
  subscriberRegistry,
) => {
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
  (envelope, {...reg, nextEventId: reg.nextEventId + 1, recentEvents: trimmed})
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
let totalEventsProcessed = (reg: subscriberRegistry): int => reg.nextEventId - 1

// ════════════════════════════════════════════════════════════════════════
// Event Batching — group envelopes by topic for efficient bulk dispatch.
// ════════════════════════════════════════════════════════════════════════

/// A batch of events grouped by topic for efficient bulk dispatch.
type eventBatch = {
  /// The topic shared by all events in this batch.
  topic: eventTopic,
  /// The envelopes in dispatch order.
  envelopes: array<eventEnvelope>,
}

/// Group an array of envelopes by topic for batched dispatch.
/// Returns one batch per distinct topic present in the input.
let batchEvents = (envelopes: array<eventEnvelope>): array<eventBatch> => {
  let topicGroups: Dict.t<array<eventEnvelope>> = Dict.make()
  envelopes->Array.forEach(env => {
    let key = topicLabel(env.topic)
    let existing = switch Dict.get(topicGroups, key) {
    | Some(arr) => arr
    | None => []
    }
    Dict.set(topicGroups, key, Array.concat(existing, [env]))
  })
  // Convert back to batches — use the topic from the first envelope.
  Dict.toArray(topicGroups)->Array.filterMap(((_, envs)) => {
    switch envs[0] {
    | Some(first) => Some({topic: first.topic, envelopes: envs})
    | None => None
    }
  })
}
