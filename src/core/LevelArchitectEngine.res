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
}
