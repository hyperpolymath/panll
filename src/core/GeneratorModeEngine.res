// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Generator Mode Engine — pure computation and helpers for the
/// parametric world builder panel.
///
/// Provides default state, tab labels, and utility functions for counting
/// districts, totalling facilities, formatting weather/time, and constructing
/// default world parameters.

open GeneratorModeModel

/// Default world generation parameters (balanced mid-range values).
let defaultWorldParams: worldParams = {
  securityLevel: 0.5,
  techLevel: 0.5,
  weatherCondition: Clear,
  timeOfDay: Afternoon,
  trapDensity: 0.3,
  civilianPopulation: 100,
  difficultyTarget: 0.5,
}

/// Default state for the Generator Mode panel.
let defaultState: generatorModeState = {
  activeTab: Design,
  currentSpec: None,
  params: defaultWorldParams,
  previewResult: None,
  generating: false,
  templates: [],
  error: None,
}

/// Human-readable label for a generator mode category tab.
let tabLabel = (cat: generatorModeCategory): string =>
  switch cat {
  | Design => "Design"
  | Parameters => "Parameters"
  | Preview => "Preview"
  | Export => "Export"
  }

/// All category tabs in display order.
let allTabs: array<generatorModeCategory> = [Design, Parameters, Preview, Export]

/// Count the number of districts in a world specification.
let countDistricts = (spec: worldSpec): int => spec.districts->Array.length

/// Count the total number of facilities across all districts.
let countTotalFacilities = (spec: worldSpec): int =>
  spec.districts->Array.reduce(0, (acc, district) =>
    acc + district.facilities->Array.reduce(0, (sum, f) => sum + f.count)
  )

/// Human-readable weather condition label.
let formatWeather = (w: weatherCondition): string =>
  switch w {
  | Clear => "Clear"
  | Rain => "Rain"
  | Snow => "Snow"
  | Fog => "Fog"
  | Storm => "Storm"
  | NightRain => "Night Rain"
  }

/// Human-readable time of day label.
let formatTimeOfDay = (t: timeOfDay): string =>
  switch t {
  | Dawn => "Dawn"
  | Morning => "Morning"
  | Afternoon => "Afternoon"
  | Evening => "Evening"
  | Night => "Night"
  | Midnight => "Midnight"
  }
