// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// PanLL Agent OODA Engine — pure helpers for the OODA session monitor panel.
///
/// All functions are pure (no side effects). Provides state colour mappings,
/// transition logic, session health indicators, and display helpers.

open AgentOodaModel

// ============================================================================
// State Colour Mappings
// ============================================================================

/// Tailwind background colour class for an agent state.
let stateColor = (state: agentState): string => {
  switch state {
  | Observing => "bg-blue-600 text-white"
  | Orienting => "bg-cyan-600 text-white"
  | Deciding => "bg-amber-500 text-white"
  | Acting => "bg-emerald-600 text-white"
  | Halted => "bg-red-600 text-white"
  }
}

/// Tailwind text colour class for an agent state.
let stateTextColor = (state: agentState): string => {
  switch state {
  | Observing => "text-blue-400"
  | Orienting => "text-cyan-400"
  | Deciding => "text-amber-400"
  | Acting => "text-emerald-400"
  | Halted => "text-red-400"
  }
}

/// Tailwind border colour class for an agent state.
let stateBorderColor = (state: agentState): string => {
  switch state {
  | Observing => "border-blue-500"
  | Orienting => "border-cyan-500"
  | Deciding => "border-amber-500"
  | Acting => "border-emerald-500"
  | Halted => "border-red-500"
  }
}

// ============================================================================
// State Icons and Labels
// ============================================================================

/// Lucide icon name for an agent state.
let stateIcon = (state: agentState): string => {
  switch state {
  | Observing => "eye"
  | Orienting => "compass"
  | Deciding => "brain"
  | Acting => "play"
  | Halted => "octagon"
  }
}

/// Human-readable label for an agent state.
let stateLabel = (state: agentState): string => {
  switch state {
  | Observing => "Observing"
  | Orienting => "Orienting"
  | Deciding => "Deciding"
  | Acting => "Acting"
  | Halted => "Halted"
  }
}

// ============================================================================
// Transition Logic
// ============================================================================

/// Whether a transition from the current state to a target state is valid.
/// OODA loops follow: Observing -> Orienting -> Deciding -> Acting -> Observing.
/// Any state can transition to Halted.
let canTransition = (current: agentState, target: agentState): bool => {
  switch (current, target) {
  | (_, Halted) => true
  | (Observing, Orienting) => true
  | (Orienting, Deciding) => true
  | (Deciding, Acting) => true
  | (Acting, Observing) => true
  | _ => false
  }
}

/// The next state in the OODA loop (does not include Halted).
let nextState = (current: agentState): agentState => {
  switch current {
  | Observing => Orienting
  | Orienting => Deciding
  | Deciding => Acting
  | Acting => Observing
  | Halted => Halted
  }
}

// ============================================================================
// Session Health
// ============================================================================

/// Health classification for a session based on loop count and state.
type sessionHealthLevel =
  /// Healthy — session is progressing normally.
  | Healthy
  /// Slow — session has a low loop rate.
  | Slow
  /// Stuck — session has not progressed.
  | Stuck
  /// Dead — session is halted.
  | Dead

/// Assess the health of a session based on its state and loop count.
let sessionHealth = (session: oodaSession): sessionHealthLevel => {
  if session.wasHalted || session.state == Halted {
    Dead
  } else if session.loopCount == 0 {
    Stuck
  } else if session.loopCount < 3 {
    Slow
  } else {
    Healthy
  }
}

/// Tailwind text colour for a health level.
let healthColor = (health: sessionHealthLevel): string => {
  switch health {
  | Healthy => "text-emerald-400"
  | Slow => "text-amber-400"
  | Stuck => "text-red-400"
  | Dead => "text-gray-500"
  }
}

/// Calculate loop rate (loops per second) from detail data.
let loopRate = (detail: sessionDetail): float => {
  if detail.totalElapsedMs > 0.0 {
    Int.toFloat(detail.session.loopCount) /. (detail.totalElapsedMs /. 1000.0)
  } else {
    0.0
  }
}

// ============================================================================
// Initial State
// ============================================================================

/// Default initial state for the OODA Session Monitor.
let init: agentOodaState = {
  sessions: [],
  selectedSessionId: None,
  selectedDetail: None,
  loading: false,
}
