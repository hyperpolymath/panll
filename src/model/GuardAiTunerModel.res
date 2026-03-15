// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Guard AI Tuner Model — types for tuning guard patrol behaviour,
/// alert thresholds, spawn rates, and detection parameters.
///
/// Guards in IDApTIK follow configurable patrol routes with tuneable
/// alertness, speed, detection range, and response time. This panel
/// lets designers create guard profiles, draw patrol routes, adjust
/// thresholds, and save/load tuning presets.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// A guard behaviour profile with tuneable AI parameters.
type guardProfile = {
  /// Unique identifier for this guard profile.
  id: string,
  /// Human-readable name (e.g., "Corridor Sentinel", "Roaming Enforcer").
  name: string,
  /// Patrol pattern name (e.g., "loop", "pingpong", "random", "stationary").
  patrolPattern: string,
  /// Alert threshold (0.0 = oblivious, 1.0 = hyper-vigilant).
  alertThreshold: float,
  /// Spawn rate multiplier (1.0 = normal, 2.0 = double frequency).
  spawnRate: float,
  /// Movement speed in units per second.
  speed: float,
  /// Detection range in world units.
  detectionRange: float,
  /// Time in seconds before the guard reacts to a detected threat.
  responseTime: float,
}

/// A single waypoint in a patrol route.
type patrolPoint = {
  /// X coordinate in world space.
  x: float,
  /// Y coordinate in world space.
  y: float,
  /// Time in seconds the guard waits at this point.
  waitTime: float,
}

/// A patrol route assigned to a specific guard.
type patrolRoute = {
  /// Unique identifier for this route.
  id: string,
  /// ID of the guard profile this route is assigned to.
  guardId: string,
  /// Ordered list of waypoints forming the patrol path.
  points: array<patrolPoint>,
  /// Whether the route loops back to the start or reverses.
  looping: bool,
}

/// A saved tuning preset containing a set of guard profiles.
type tuningPreset = {
  /// Preset name (e.g., "Easy Mode", "Nightmare Security").
  name: string,
  /// Human-readable description of the preset's design intent.
  description: string,
  /// Guard profiles included in this preset.
  profiles: array<guardProfile>,
}

/// Category tabs for the Guard AI Tuner panel.
type guardAiTunerCategory =
  /// Guard profile list and editor.
  | Profiles
  /// Visual patrol route editor.
  | PatrolEditor
  /// Alert threshold and detection sliders.
  | Thresholds
  /// Saved tuning presets browser.
  | Presets

/// Root state for the Guard AI Tuner panel.
type guardAiTunerState = {
  /// Active category tab.
  activeTab: guardAiTunerCategory,
  /// All guard profiles in the current level.
  guards: array<guardProfile>,
  /// All patrol routes defined for guards.
  routes: array<patrolRoute>,
  /// Saved tuning presets.
  presets: array<tuningPreset>,
  /// Currently selected guard profile (if any).
  selectedGuard: option<string>,
  /// Whether a guard profile is currently being edited.
  editing: bool,
  /// Error message (if any).
  error: option<string>,
}
