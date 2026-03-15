// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Generator Mode Model — types for the parametric world builder panel.
///
/// Users describe worlds compositionally using sliders, toggles, and structured
/// specs. Districts are composed of facilities, and global parameters control
/// security level, tech level, weather, time of day, trap density, civilian
/// population, and difficulty targeting.
///
/// The generator produces a LevelConfig JSON from the world specification,
/// validates entity counts, and provides a live preview before export.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// District classification within a generated world.
type districtType =
  /// Residential housing blocks and apartments.
  | Residential
  /// Commercial office parks, shops, and markets.
  | Commercial
  /// Military installations and barracks.
  | Military
  /// Industrial factories, warehouses, and plants.
  | Industrial
  /// Government buildings, embassies, and civic centres.
  | Government
  /// Transport hubs: stations, airports, docks.
  | Transport
  /// Historic landmarks, museums, and heritage sites.
  | Historic

/// Specification for a single facility within a district.
type facilitySpec = {
  /// Facility type name (e.g., "Server Room", "Guard Post", "Elevator").
  facilityType: string,
  /// Number of instances to generate.
  count: int,
  /// Optional variant modifier (e.g., "reinforced", "covert").
  variant: option<string>,
}

/// Specification for a district containing multiple facilities.
type districtSpec = {
  /// Classification of the district.
  districtType: districtType,
  /// Facilities to place inside this district.
  facilities: array<facilitySpec>,
  /// Hint for relative district size (e.g., "small", "medium", "large").
  sizeHint: string,
}

/// Weather condition for the generated world.
type weatherCondition =
  /// Clear skies, full visibility.
  | Clear
  /// Rain — reduced visibility, wet surfaces.
  | Rain
  /// Snow — slowed movement, muffled sound.
  | Snow
  /// Fog — heavily reduced visibility range.
  | Fog
  /// Storm — lightning flashes, power outages possible.
  | Storm
  /// Night rain — combines darkness with rain effects.
  | NightRain

/// Time of day affecting lighting and guard schedules.
type timeOfDay =
  /// Early morning, low light, shift change.
  | Dawn
  /// Full daylight, peak civilian activity.
  | Morning
  /// Bright daylight, moderate activity.
  | Afternoon
  /// Fading light, guards transitioning to night shift.
  | Evening
  /// Darkness, reduced civilian presence, heightened security.
  | Night
  /// Deep night, skeleton crew, lowest civilian count.
  | Midnight

/// Global parameters controlling world-wide generation settings.
type worldParams = {
  /// Overall security level (0.0 = minimal, 1.0 = maximum lockdown).
  securityLevel: float,
  /// Technology level (0.0 = low-tech, 1.0 = cutting-edge).
  techLevel: float,
  /// Current weather condition in the generated world.
  weatherCondition: weatherCondition,
  /// Time of day affecting lighting and NPC schedules.
  timeOfDay: timeOfDay,
  /// Trap density (0.0 = no traps, 1.0 = heavily trapped).
  trapDensity: float,
  /// Number of civilian NPCs to populate the world.
  civilianPopulation: int,
  /// Target difficulty rating (0.0 = trivial, 1.0 = extreme).
  difficultyTarget: float,
}

/// Complete world specification composed of districts and global parameters.
type worldSpec = {
  /// Human-readable name for this world.
  name: string,
  /// Districts composing the world layout.
  districts: array<districtSpec>,
  /// Global generation parameters.
  globalParams: worldParams,
}

/// Result of running the world generator on a worldSpec.
type generationResult = {
  /// The world specification that was used for generation.
  worldSpec: worldSpec,
  /// Serialised LevelConfig JSON output.
  levelConfigJson: string,
  /// Total number of entities placed.
  entityCount: int,
  /// Whether all validation checks passed.
  validationPassed: bool,
  /// ISO 8601 timestamp of when the generation completed.
  generatedAt: string,
}

/// Category tabs for the Generator Mode panel.
type generatorModeCategory =
  /// District and facility design editor.
  | Design
  /// Global parameter sliders and toggles.
  | Parameters
  /// Live preview of the generated world.
  | Preview
  /// Export to LevelConfig JSON.
  | Export

/// Root state for the Generator Mode panel.
type generatorModeState = {
  /// Active category tab.
  activeTab: generatorModeCategory,
  /// The world specification currently being designed.
  currentSpec: option<worldSpec>,
  /// Current global generation parameters.
  params: worldParams,
  /// Result of the last generation run (if any).
  previewResult: option<generationResult>,
  /// Whether the generator is currently running.
  generating: bool,
  /// Saved world templates for quick reuse.
  templates: array<worldSpec>,
  /// Error message (if any).
  error: option<string>,
}
