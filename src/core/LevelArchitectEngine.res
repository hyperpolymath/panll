// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Level Architect Engine — pure computation and helpers for the
/// IDApTIK visual level design tool.

open LevelArchitectModel

/// Human-readable labels for category tabs.
let categoryLabel = (cat: levelArchitectCategory): string =>
  switch cat {
  | ArchitectGrid => "Grid"
  | ArchitectAssets => "Assets"
  | ArchitectPatrols => "Patrols"
  | ArchitectValidation => "Validation"
  }

/// Human-readable labels for entity kinds.
let entityKindLabel = (kind: levelEntityKind): string =>
  switch kind {
  | EntityDevice => "Device"
  | EntityGuard => "Guard"
  | EntitySpawnPoint => "Spawn Point"
  | EntityCompanion => "Companion"
  | EntityCollectable => "Collectable"
  | EntityTrigger => "Trigger"
  | EntityDecoration => "Decoration"
  }

/// Icon for entity kinds (Lucide icon names).
let entityKindIcon = (kind: levelEntityKind): string =>
  switch kind {
  | EntityDevice => "monitor"
  | EntityGuard => "shield-alert"
  | EntitySpawnPoint => "map-pin"
  | EntityCompanion => "bot"
  | EntityCollectable => "gem"
  | EntityTrigger => "zap"
  | EntityDecoration => "palette"
  }

/// Human-readable labels for defence flags.
let defenceFlagLabel = (flag: defenceFlag): string =>
  switch flag {
  | FlagFirewall => "Firewall"
  | FlagIDS => "IDS/IPS"
  | FlagEncryption => "Encryption"
  | FlagMFA => "Multi-Factor Auth"
  | FlagBackup => "Backup"
  | FlagAuditLog => "Audit Logging"
  | FlagAccessControl => "Access Control"
  | FlagPatching => "Patching"
  | FlagSegmentation => "Network Segmentation"
  | FlagIncidentResponse => "Incident Response"
  | FlagPhysicalSecurity => "Physical Security"
  }

/// All 11 defence flags.
let allDefenceFlags: array<defenceFlag> = [
  FlagFirewall,
  FlagIDS,
  FlagEncryption,
  FlagMFA,
  FlagBackup,
  FlagAuditLog,
  FlagAccessControl,
  FlagPatching,
  FlagSegmentation,
  FlagIncidentResponse,
  FlagPhysicalSecurity,
]

/// Human-readable tool label.
let toolLabel = (tool: editorTool): string =>
  switch tool {
  | ToolSelect => "Select"
  | ToolPlace(kind) => `Place ${entityKindLabel(kind)}`
  | ToolErase => "Erase"
  | ToolPatrol => "Patrol Path"
  | ToolDefenceFlag => "Defence Flag"
  }

/// Count entities by kind.
let countByKind = (entities: array<levelEntity>, kind: levelEntityKind): int =>
  entities->Array.filter(e => e.kind === kind)->Array.length

/// Check if a grid cell is occupied.
let isOccupied = (entities: array<levelEntity>, x: int, y: int): bool =>
  entities->Array.some(e => e.gridX === x && e.gridY === y)

/// Default zones matching IDApTIK standard layout.
let defaultUmsZones: array<levelZone> = [
  {name: "LAN", startX: 0.0, endX: 1500.0, securityTier: 1},
  {name: "DMZ", startX: 1500.0, endX: 3500.0, securityTier: 2},
  {name: "SCADA", startX: 3500.0, endX: 5000.0, securityTier: 3},
]

/// Device kind labels.
let deviceKindLabel = (dk: deviceKind): string =>
  switch dk {
  | DevLaptop => "Laptop"
  | DevDesktop => "Desktop"
  | DevServer => "Server"
  | DevRouter => "Router"
  | DevSwitch => "Switch"
  | DevFirewall => "Firewall"
  | DevCamera => "Camera"
  | DevAccessPoint => "Access Point"
  | DevPatchPanel => "Patch Panel"
  | DevPowerSupply => "Power Supply"
  | DevPhoneSystem => "Phone System"
  | DevFibreHub => "Fibre Hub"
  }

/// Guard rank labels.
let guardRankLabel = (gr: guardRank): string =>
  switch gr {
  | RankBasic => "Basic"
  | RankEnforcer => "Enforcer"
  | RankAntiHacker => "Anti-Hacker"
  | RankSentinel => "Sentinel"
  | RankAssassin => "Assassin"
  | RankElite => "Elite"
  | RankSecurityChief => "Security Chief"
  | RankRivalHacker => "Rival Hacker"
  }

/// Dog breed labels.
let dogBreedLabel = (db: dogBreed): string =>
  switch db {
  | BreedPatrol => "Patrol"
  | BreedBloodhound => "Bloodhound"
  | BreedRoboDog => "RoboDog"
  }

/// Drone archetype labels.
let droneArchetypeLabel = (da: droneArchetype): string =>
  switch da {
  | DroneHelper => "Helper"
  | DroneHunter => "Hunter"
  | DroneKiller => "Killer"
  }

/// Security level labels.
let securityLevelLabel = (sl: securityLevel): string =>
  switch sl {
  | SecOpen => "Open"
  | SecWeak => "Weak"
  | SecMedium => "Medium"
  | SecStrong => "Strong"
  }

/// Convert Level Architect entities to UMS JSON format for validation.
let toUmsJson = (state: levelArchitectState): string => {
  let entitiesJson = state.entities->Array.map(e => {
    `{"id":"${e.id}","kind":"${entityKindLabel(e.kind)}","name":"${e.name}","gridX":${Int.toString(e.gridX)},"gridY":${Int.toString(e.gridY)}}`
  })->Array.join(",")
  let zonesJson = state.zones->Array.map(z => {
    `{"name":"${z.name}","startX":${Float.toString(z.startX)},"endX":${Float.toString(z.endX)},"securityTier":${Int.toString(z.securityTier)}}`
  })->Array.join(",")
  let patrolsJson = state.patrols->Array.map(p => {
    let wps = p.waypoints->Array.map(w =>
      `{"x":${Int.toString(w.x)},"y":${Int.toString(w.y)},"pauseDuration":${Float.toString(w.pauseDuration)}}`
    )->Array.join(",")
    `{"guardId":"${p.guardId}","waypoints":[${wps}],"looping":${p.looping ? "true" : "false"},"speed":${Float.toString(p.speed)}}`
  })->Array.join(",")
  let flagsJson = state.defenceFlags->Array.map(f => `"${defenceFlagLabel(f)}"`)->Array.join(",")
  `{"levelName":"${state.levelName}","gridWidth":${Int.toString(state.gridWidth)},"gridHeight":${Int.toString(state.gridHeight)},"entities":[${entitiesJson}],"zones":[${zonesJson}],"patrols":[${patrolsJson}],"defenceFlags":[${flagsJson}]}`
}

/// Parse UMS validation result JSON.
let parseUmsValidation = (jsonStr: string): option<umsValidation> => {
  try {
    let json = JSON.parseExn(jsonStr)
    let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
    let getBool = (key: string) =>
      obj->Dict.get(key)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
    let proofsArr = obj->Dict.get("proofs")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
    let proofs = proofsArr->Array.filterMap(p => {
      let pObj = p->JSON.Decode.object->Option.getOr(Dict.make())
      let name = pObj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      let passed = pObj->Dict.get("passed")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
      let detail = pObj->Dict.get("detail")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      Some({name, passed, detail})
    })
    Some({
      guardsInZones: getBool("guardsInZones"),
      defenceTargetsValid: getBool("defenceTargetsValid"),
      zonesOrdered: getBool("zonesOrdered"),
      pbxConsistent: getBool("pbxConsistent"),
      devicesExist: getBool("devicesExist"),
      allPassed: getBool("allPassed"),
      proofs,
    })
  } catch {
  | _ => None
  }
}

/// All device kinds for dropdowns.
let allDeviceKinds: array<deviceKind> = [
  DevLaptop, DevDesktop, DevServer, DevRouter, DevSwitch,
  DevFirewall, DevCamera, DevAccessPoint, DevPatchPanel,
  DevPowerSupply, DevPhoneSystem, DevFibreHub,
]

/// All guard ranks for dropdowns.
let allGuardRanks: array<guardRank> = [
  RankBasic, RankEnforcer, RankAntiHacker, RankSentinel,
  RankAssassin, RankElite, RankSecurityChief, RankRivalHacker,
]

/// All dog breeds for dropdowns.
let allDogBreeds: array<dogBreed> = [BreedPatrol, BreedBloodhound, BreedRoboDog]

/// All drone archetypes for dropdowns.
let allDroneArchetypes: array<droneArchetype> = [DroneHelper, DroneHunter, DroneKiller]

/// All security levels for dropdowns.
let allSecurityLevels: array<securityLevel> = [SecOpen, SecWeak, SecMedium, SecStrong]

/// Default state for the Level Architect panel.
let defaultState: levelArchitectState = {
  activeCategory: ArchitectGrid,
  levelName: "Untitled Level",
  gridWidth: 20,
  gridHeight: 15,
  entities: [],
  patrols: [],
  defenceFlags: [],
  selectedEntityId: None,
  selectedTool: ToolSelect,
  assets: [],
  validationIssues: [],
  history: [],
  historyIndex: -1,
  zoomLevel: 1.0,
  showGrid: true,
  showPatrolPaths: true,
  showDefenceOverlay: false,
  alertThreshold: 3,
  loading: false,
  error: None,
  zones: defaultUmsZones,
  umsValidation: None,
  bojRouting: false,
}
