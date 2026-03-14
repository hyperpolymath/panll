// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Level Architect Model — types for the IDApTIK visual level
/// design tool. Device placement, guard patrols, defence flags, asset
/// browser, level validation, and LevelConfig export.

/// Entity types that can be placed on a level grid.
type levelEntityKind =
  | EntityDevice
  | EntityGuard
  | EntitySpawnPoint
  | EntityCompanion
  | EntityCollectable
  | EntityTrigger
  | EntityDecoration

/// A placed entity on the level grid.
type levelEntity = {
  id: string,
  kind: levelEntityKind,
  name: string,
  gridX: int,
  gridY: int,
  rotation: int,
  properties: array<(string, string)>,
}

/// Guard patrol waypoint.
type patrolWaypoint = {
  x: int,
  y: int,
  pauseDuration: float,
}

/// Guard patrol definition.
type guardPatrol = {
  guardId: string,
  waypoints: array<patrolWaypoint>,
  looping: bool,
  speed: float,
}

/// IDApTIK defence flag (11 flags).
type defenceFlag =
  | FlagFirewall
  | FlagIDS
  | FlagEncryption
  | FlagMFA
  | FlagBackup
  | FlagAuditLog
  | FlagAccessControl
  | FlagPatching
  | FlagSegmentation
  | FlagIncidentResponse
  | FlagPhysicalSecurity

/// Level validation issue.
type validationIssue = {
  severity: string,
  message: string,
  entityId: option<string>,
  gridX: option<int>,
  gridY: option<int>,
}

/// A game asset in the browser.
type levelAsset = {
  id: string,
  name: string,
  category: string,
  thumbnail: string,
  entityKind: levelEntityKind,
}

/// Undo history entry.
type levelHistoryEntry = {
  description: string,
  entities: array<levelEntity>,
  patrols: array<guardPatrol>,
}

/// The editor tool currently selected.
type editorTool =
  | ToolSelect
  | ToolPlace(levelEntityKind)
  | ToolErase
  | ToolPatrol
  | ToolDefenceFlag

/// Category tabs for the Level Architect panel.
type levelArchitectCategory =
  | ArchitectGrid
  | ArchitectAssets
  | ArchitectPatrols
  | ArchitectValidation

/// IDApTIK device kind (mirrors Idris2 Types.idr DeviceKind).
type deviceKind =
  | DevLaptop
  | DevDesktop
  | DevServer
  | DevRouter
  | DevSwitch
  | DevFirewall
  | DevCamera
  | DevAccessPoint
  | DevPatchPanel
  | DevPowerSupply
  | DevPhoneSystem
  | DevFibreHub

/// IDApTIK guard rank (mirrors Idris2 Types.idr GuardRank).
type guardRank =
  | RankBasic
  | RankEnforcer
  | RankAntiHacker
  | RankSentinel
  | RankAssassin
  | RankElite
  | RankSecurityChief
  | RankRivalHacker

/// IDApTIK security dog breed (mirrors Idris2 Types.idr DogBreed).
type dogBreed = BreedPatrol | BreedBloodhound | BreedRoboDog

/// IDApTIK drone archetype (mirrors Idris2 Types.idr DroneArchetype).
type droneArchetype = DroneHelper | DroneHunter | DroneKiller

/// Security level (mirrors Idris2 Primitives.idr SecurityLevel).
type securityLevel = SecOpen | SecWeak | SecMedium | SecStrong

/// A security zone with boundaries (mirrors Idris2 Zones.idr).
type levelZone = {
  name: string,
  startX: float,
  endX: float,
  securityTier: int,
}

/// ABI proof validation result (mirrors Validation.idr).
type abiProof = {
  name: string,
  passed: bool,
  detail: string,
}

/// UMS-format validation state (the 5 Idris2 proofs).
type umsValidation = {
  guardsInZones: bool,
  defenceTargetsValid: bool,
  zonesOrdered: bool,
  pbxConsistent: bool,
  devicesExist: bool,
  allPassed: bool,
  proofs: array<abiProof>,
}

/// Root state for the Level Architect panel.
type levelArchitectState = {
  activeCategory: levelArchitectCategory,
  levelName: string,
  gridWidth: int,
  gridHeight: int,
  entities: array<levelEntity>,
  patrols: array<guardPatrol>,
  defenceFlags: array<defenceFlag>,
  selectedEntityId: option<string>,
  selectedTool: editorTool,
  assets: array<levelAsset>,
  validationIssues: array<validationIssue>,
  history: array<levelHistoryEntry>,
  historyIndex: int,
  zoomLevel: float,
  showGrid: bool,
  showPatrolPaths: bool,
  showDefenceOverlay: bool,
  alertThreshold: int,
  loading: bool,
  error: option<string>,
  /// UMS-format zones (LAN/DMZ/SCADA).
  zones: array<levelZone>,
  /// UMS ABI validation result.
  umsValidation: option<umsValidation>,
  /// BoJ routing toggle.
  bojRouting: bool,
}
