// SPDX-License-Identifier: MPL-2.0

/// PanLL Architect Mode Model — types for the fine-grained PixiJS level
/// editor with Layout / Nodes / Wiring three-panel architecture.
///
/// Provides entity placement, zone painting, wire connections, undo/redo,
/// AI suggestions, grid snapping, and zoom/pan controls. This is the
/// detailed editor counterpart to GeneratorMode's parametric approach.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// Editor tool currently selected in the canvas toolbar.
type architectEditorTool =
  /// Select and move existing entities or zones.
  | SelectTool
  /// Place a new entity of the given kind string.
  | PlaceTool(string)
  /// Erase entities or zones under the cursor.
  | EraseTool
  /// Draw wire connections between devices.
  | WireTool
  /// Paint security zones on the canvas.
  | ZoneTool
  /// Pan the canvas without modifying entities.
  | PanTool

/// An entity placed on the PixiJS canvas.
type placedEntity = {
  /// Unique identifier for this entity.
  id: string,
  /// Entity kind name (e.g., "Guard", "Camera", "Server").
  kind: string,
  /// X position on the canvas in world coordinates.
  x: float,
  /// Y position on the canvas in world coordinates.
  y: float,
  /// Rotation in degrees (0–360).
  rotation: float,
  /// Key-value properties for this entity instance.
  properties: Dict.t<string>,
  /// Whether this entity is currently selected.
  selected: bool,
}

/// A security zone region painted on the canvas.
type zoneRegion = {
  /// Unique identifier for this zone.
  id: string,
  /// Human-readable zone name (e.g., "Server Room", "DMZ").
  name: string,
  /// Zone classification (e.g., "LAN", "DMZ", "SCADA", "Restricted").
  zoneType: string,
  /// Top-left X coordinate in world space.
  x: float,
  /// Top-left Y coordinate in world space.
  y: float,
  /// Width of the zone region.
  width: float,
  /// Height of the zone region.
  height: float,
  /// Security tier (0 = open, higher = more restricted).
  securityTier: int,
}

/// An undoable action recorded in the undo stack.
type undoAction =
  /// An entity was placed (stores entity ID for removal).
  | EntityPlaced(string)
  /// An entity was moved (stores entity ID, previous x, previous y).
  | EntityMoved(string, float, float)
  /// An entity was deleted (stores full entity for restoration).
  | EntityDeleted(placedEntity)
  /// A zone was created (stores zone ID for removal).
  | ZoneCreated(string)
  /// A zone was resized (stores zone ID, previous x, y, width, height).
  | ZoneResized(string, float, float, float, float)
  /// A property was changed (stores entity ID, key, old value, new value).
  | PropertyChanged(string, string, string, string)

/// An AI-generated suggestion for entity placement or layout improvement.
type aiSuggestion = {
  /// Unique identifier for this suggestion.
  id: string,
  /// Human-readable description of what the AI suggests.
  description: string,
  /// Entities the AI recommends placing.
  entities: array<placedEntity>,
  /// Confidence score (0.0–1.0) for this suggestion.
  confidence: float,
  /// Whether the user has applied this suggestion.
  applied: bool,
}

/// Category tabs for the Architect Mode panel.
type architectModeCategory =
  /// Main PixiJS canvas for entity and zone placement.
  | Canvas
  /// Properties inspector for the selected entity or zone.
  | Properties
  /// AI-generated layout suggestions.
  | AiSuggestions
  /// Level validation results and error list.
  | Validation

/// Root state for the Architect Mode panel.
type architectModeState = {
  /// Active category tab.
  activeTab: architectModeCategory,
  /// All entities placed on the canvas.
  entities: array<placedEntity>,
  /// All security zones painted on the canvas.
  zones: array<zoneRegion>,
  /// Currently selected editor tool.
  selectedTool: architectEditorTool,
  /// ID of the currently selected entity (if any).
  selectedEntityId: option<string>,
  /// Undo history stack.
  undoStack: array<undoAction>,
  /// Redo history stack.
  redoStack: array<undoAction>,
  /// AI-generated suggestions for the current layout.
  aiSuggestions: array<aiSuggestion>,
  /// Whether the grid overlay is visible.
  gridVisible: bool,
  /// Whether entity placement snaps to the grid.
  snapToGrid: bool,
  /// Grid cell size in pixels.
  gridSize: int,
  /// Current zoom level (1.0 = default).
  zoom: float,
  /// Horizontal pan offset in world coordinates.
  panX: float,
  /// Vertical pan offset in world coordinates.
  panY: float,
  /// Error message (if any).
  error: option<string>,
}
