// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Tentacles Engine — pure helpers for the 7-Tentacles agent panel.
///
/// All functions are pure (no side effects). Provides init state, colour
/// mappings, stage labels, agent lookups, and OODA phase helpers.

open PaneModel
open TentaclesModel

/// Hex colour for a tentacle agent, matching the 7-tentacles spec.
let tentacleHex = (id: tentacleId): string => {
  switch id {
  | Red => "#E74C3C"
  | Orange => "#E67E22"
  | Yellow => "#F1C40F"
  | Green => "#2ECC71"
  | Blue => "#3498DB"
  | Indigo => "#9B59B6"
  | Violet => "#8E44AD"
  }
}

/// Tailwind text colour class for a tentacle agent.
let tentacleTextClass = (id: tentacleId): string => {
  switch id {
  | Red => "text-red-400"
  | Orange => "text-orange-400"
  | Yellow => "text-yellow-400"
  | Green => "text-emerald-400"
  | Blue => "text-blue-400"
  | Indigo => "text-purple-400"
  | Violet => "text-violet-400"
  }
}

/// Tailwind border colour class for a tentacle agent.
let tentacleBorderClass = (id: tentacleId): string => {
  switch id {
  | Red => "border-red-500"
  | Orange => "border-orange-500"
  | Yellow => "border-yellow-500"
  | Green => "border-emerald-500"
  | Blue => "border-blue-500"
  | Indigo => "border-purple-500"
  | Violet => "border-violet-500"
  }
}

/// Tailwind background colour class for a tentacle agent (subtle, for cards).
let tentacleBgClass = (id: tentacleId): string => {
  switch id {
  | Red => "bg-red-900/20"
  | Orange => "bg-orange-900/20"
  | Yellow => "bg-yellow-900/20"
  | Green => "bg-emerald-900/20"
  | Blue => "bg-blue-900/20"
  | Indigo => "bg-purple-900/20"
  | Violet => "bg-violet-900/20"
  }
}

/// Human-readable label for a tentacle ID.
let tentacleLabel = (id: tentacleId): string => {
  switch id {
  | Red => "Red (Parser)"
  | Orange => "Orange (Concurrency)"
  | Yellow => "Yellow (Type System)"
  | Green => "Green (AST Architect)"
  | Blue => "Blue (Auditor)"
  | Indigo => "Indigo (Metaprogrammer)"
  | Violet => "Violet (Governance)"
  }
}

/// Short label (colour name only).
let tentacleShortLabel = (id: tentacleId): string => {
  switch id {
  | Red => "Red"
  | Orange => "Orange"
  | Yellow => "Yellow"
  | Green => "Green"
  | Blue => "Blue"
  | Indigo => "Indigo"
  | Violet => "Violet"
  }
}

/// Compiler role description for a tentacle.
let tentacleRole = (id: tentacleId): string => {
  switch id {
  | Red => "Parser"
  | Orange => "Concurrency Engine"
  | Yellow => "Type System"
  | Green => "AST Architect"
  | Blue => "Auditor"
  | Indigo => "Metaprogrammer"
  | Violet => "Governance"
  }
}

/// Human-readable stage label.
let stageLabel = (s: tentacleStage): string => {
  switch s {
  | Cuttle => "Cuttle (8-12)"
  | Squidlet => "Squidlet (13-14)"
  | Duet => "Duet (15)"
  | Octopus => "Octopus (16+)"
  }
}

/// OODA phase label.
let oodaLabel = (p: oodaPhase): string => {
  switch p {
  | Observe => "Observe"
  | Orient => "Orient"
  | Decide => "Decide"
  | Act => "Act"
  }
}

/// OODA phase icon (text glyph, not emoji per project rules).
let oodaIcon = (p: oodaPhase): string => {
  switch p {
  | Observe => "[O]"
  | Orient => "[R]"
  | Decide => "[D]"
  | Act => "[A]"
  }
}

/// Category label for the tab bar.
let categoryLabel = (c: tentaclesCategory): string => {
  switch c {
  | AgentView => "Agent"
  | Orchestra => "Orchestra"
  | StageConfig => "Stage"
  | Progress => "Progress"
  }
}

/// All tentacle IDs in spectrum order.
let allTentacles: array<tentacleId> = [Red, Orange, Yellow, Green, Blue, Indigo, Violet]

/// All categories.
let allCategories: array<tentaclesCategory> = [AgentView, Orchestra, StageConfig, Progress]

/// All stages in order.
let allStages: array<tentacleStage> = [Cuttle, Squidlet, Duet, Octopus]

/// Default personality for an agent.
let defaultPersonality = (id: tentacleId): tentaclePersonality => {
  switch id {
  | Red => {
      voice: "Quick and precise, like a parser scanning tokens",
      catchphrase: "Every program starts with a single token!",
      encouragement: ["Clean parse!", "Syntax perfect!", "No ambiguity there!"],
      corrections: ["Watch your brackets...", "That token looks off", "Check the grammar"],
      celebrations: ["Full parse tree built!", "Zero syntax errors!", "Grammar mastered!"],
    }
  | Orange => {
      voice: "Rhythmic and parallel, like concurrent threads dancing",
      catchphrase: "Everything happens at once — if you plan it right!",
      encouragement: ["Nice scheduling!", "No deadlocks!", "Parallel perfection!"],
      corrections: ["Race condition spotted", "Check that lock order", "Sync point missing"],
      celebrations: ["All threads harmonised!", "Zero contention!", "True parallelism achieved!"],
    }
  | Yellow => {
      voice: "Methodical and precise, like a type checker unifying constraints",
      catchphrase: "If the types check, the program works!",
      encouragement: ["Types align!", "Well-constrained!", "Inference successful!"],
      corrections: ["Type mismatch detected", "Constraint unsatisfiable", "Generic bound missing"],
      celebrations: ["All types unified!", "Sound and complete!", "Type safety proven!"],
    }
  | Green => {
      voice: "Creative and structural, like an architect designing a cathedral",
      catchphrase: "Every AST tells a story — let's make it elegant!",
      encouragement: ["Beautiful structure!", "Clean transformation!", "Elegant tree!"],
      corrections: ["Node out of place", "Subtree needs rework", "Optimisation missed"],
      celebrations: ["AST optimised!", "Transformation complete!", "Architecture perfected!"],
    }
  | Blue => {
      voice: "Thorough and fair, like an auditor checking every line",
      catchphrase: "Trust, but verify — then verify again!",
      encouragement: ["Clean audit!", "Standards met!", "Good coverage!"],
      corrections: ["Anti-pattern detected", "Coverage gap found", "Standard violated"],
      celebrations: ["Full compliance!", "100% coverage!", "Audit passed with flying colours!"],
    }
  | Indigo => {
      voice: "Recursive and meta, like code that writes itself",
      catchphrase: "Why write code when code can write code?",
      encouragement: ["Elegant macro!", "Clean expansion!", "Meta-level mastery!"],
      corrections: ["Expansion diverging", "Template error", "Macro hygiene breach"],
      celebrations: ["Metaprogram complete!", "Self-modifying success!", "Abstraction achieved!"],
    }
  | Violet => {
      voice: "Authoritative yet kind, like a wise governance council",
      catchphrase: "Good governance makes great software!",
      encouragement: ["Policy compliant!", "License clear!", "Security approved!"],
      corrections: ["Policy violation", "License conflict", "Security concern"],
      celebrations: ["Governance complete!", "All policies satisfied!", "Ship it!"],
    }
  }
}

/// Default stage-specific names for an agent.
let defaultNames = (id: tentacleId): tentacleNames => {
  switch id {
  | Red => {
      cuttle: "Ruby Cuttle",
      squidlet: "Scarlet Squidlet",
      duet: "Crimson Duet",
      octopus: "Red Octopus",
    }
  | Orange => {
      cuttle: "Amber Cuttle",
      squidlet: "Tangerine Squidlet",
      duet: "Flame Duet",
      octopus: "Orange Octopus",
    }
  | Yellow => {
      cuttle: "Sunny Cuttle",
      squidlet: "Gold Squidlet",
      duet: "Lemon Duet",
      octopus: "Yellow Octopus",
    }
  | Green => {
      cuttle: "Jade Cuttle",
      squidlet: "Emerald Squidlet",
      duet: "Forest Duet",
      octopus: "Green Octopus",
    }
  | Blue => {
      cuttle: "Sky Cuttle",
      squidlet: "Azure Squidlet",
      duet: "Sapphire Duet",
      octopus: "Blue Octopus",
    }
  | Indigo => {
      cuttle: "Iris Cuttle",
      squidlet: "Mystic Squidlet",
      duet: "Indigo Duet",
      octopus: "Indigo Octopus",
    }
  | Violet => {
      cuttle: "Plum Cuttle",
      squidlet: "Orchid Squidlet",
      duet: "Violet Duet",
      octopus: "Violet Octopus",
    }
  }
}

/// Topics each agent teaches.
let tentacleTeaches = (id: tentacleId): array<string> => {
  switch id {
  | Red => ["Tokenisation", "Grammars", "Syntax trees", "Error recovery"]
  | Orange => ["Threads", "Scheduling", "Deadlock prevention", "Message passing"]
  | Yellow => ["Type inference", "Generics", "Constraints", "Soundness"]
  | Green => ["AST transforms", "Optimisation passes", "IR design", "Code generation"]
  | Blue => ["Code review", "Linting", "Coverage", "Standards enforcement"]
  | Indigo => ["Macros", "Templates", "Code generation", "DSL design"]
  | Violet => ["Licensing", "Security policy", "Dependency audit", "Release governance"]
  }
}

/// Build the initial state for a single agent.
let initAgent = (id: tentacleId, stage: tentacleStage): tentacleAgentState => {
  id,
  stage,
  personality: defaultPersonality(id),
  names: defaultNames(id),
  compilerRole: tentacleRole(id),
  teaches: tentacleTeaches(id),
  constraints: [],
  reasoning: [],
  results: [],
  currentPhase: Observe,
  busy: false,
  currentTask: None,
  lastError: None,
}

/// Get the stage-appropriate display name for an agent.
let agentDisplayName = (agent: tentacleAgentState): string => {
  switch agent.stage {
  | Cuttle => agent.names.cuttle
  | Squidlet => agent.names.squidlet
  | Duet => agent.names.duet
  | Octopus => agent.names.octopus
  }
}

/// Find an agent by ID in the agents array.
let findAgent = (agents: array<tentacleAgentState>, id: tentacleId): option<tentacleAgentState> => {
  agents->Array.find(a => a.id == id)
}

/// Update a specific agent in the agents array.
let updateAgent = (
  agents: array<tentacleAgentState>,
  id: tentacleId,
  f: tentacleAgentState => tentacleAgentState,
): array<tentacleAgentState> => {
  agents->Array.map(a => a.id == id ? f(a) : a)
}

/// Count busy agents.
let busyCount = (agents: array<tentacleAgentState>): int => {
  agents->Array.filter(a => a.busy)->Array.length
}

/// Count agents with errors.
let errorCount = (agents: array<tentacleAgentState>): int => {
  agents->Array.filter(a => a.lastError->Option.isSome)->Array.length
}

/// Total constraints across all agents.
let totalConstraints = (agents: array<tentacleAgentState>): int => {
  agents->Array.reduce(0, (acc, a) => acc + Array.length(a.constraints))
}

/// Total results across all agents.
let totalResults = (agents: array<tentacleAgentState>): int => {
  agents->Array.reduce(0, (acc, a) => acc + Array.length(a.results))
}

// ---------------------------------------------------------------------------
// S1: OODA phase progression — advance agents through Observe→Orient→Decide→Act
// ---------------------------------------------------------------------------

/// Next OODA phase in the cycle.
let nextPhase = (phase: oodaPhase): oodaPhase => {
  switch phase {
  | Observe => Orient
  | Orient => Decide
  | Decide => Act
  | Act => Observe // Cycle restarts
  }
}

/// Whether an agent has completed a full OODA cycle (returned to Observe after Act).
let cycleComplete = (prevPhase: oodaPhase, newPhase: oodaPhase): bool => {
  prevPhase == Act && newPhase == Observe
}

/// Advance an agent's OODA phase. Returns the updated agent and whether
/// the cycle completed (Act → Observe transition).
let advancePhase = (agent: tentacleAgentState): (tentacleAgentState, bool) => {
  let prev = agent.currentPhase
  let next = nextPhase(prev)
  let completed = cycleComplete(prev, next)
  let updatedAgent = {
    ...agent,
    currentPhase: next,
    // When cycle completes, agent is no longer busy.
    busy: completed ? false : agent.busy,
    // Clear the task on cycle completion.
    currentTask: completed ? None : agent.currentTask,
  }
  (updatedAgent, completed)
}

/// Start a task: set the agent to busy at the Observe phase.
let startTask = (agent: tentacleAgentState, task: string): tentacleAgentState => {
  {
    ...agent,
    busy: true,
    currentPhase: Observe,
    currentTask: Some(task),
    lastError: None,
  }
}

/// Fail a task: set error state and stop the agent.
let failTask = (agent: tentacleAgentState, error: string): tentacleAgentState => {
  {
    ...agent,
    busy: false,
    currentTask: None,
    lastError: Some(error),
  }
}

/// Build the initial tentacles panel state.
let init = (): tentaclesState => {
  agents: allTentacles->Array.map(id => initAgent(id, Cuttle)),
  selectedAgent: Red,
  activeCategory: Orchestra,
  globalStage: Cuttle,
  orchestraCompact: false,
  pendingBroadcasts: [],
  ffiConnected: false,
  ffiLastCheck: 0.0,
  ffiError: None,
}
