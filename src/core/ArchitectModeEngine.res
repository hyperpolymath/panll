// SPDX-License-Identifier: MPL-2.0

/// PanLL Architect Mode Engine — pure computation and helpers for the
/// fine-grained PixiJS level editor panel.
///
/// Provides default state, tab labels, and utility functions for counting
/// selected entities, grouping by kind, generating tool labels, and
/// checking undo/redo availability.

open ArchitectModeModel

/// Default state for the Architect Mode panel.
let defaultState: architectModeState = {
  activeTab: Canvas,
  entities: [],
  zones: [],
  selectedTool: SelectTool,
  selectedEntityId: None,
  undoStack: [],
  redoStack: [],
  aiSuggestions: [],
  gridVisible: true,
  snapToGrid: true,
  gridSize: 32,
  zoom: 1.0,
  panX: 0.0,
  panY: 0.0,
  error: None,
}

/// Human-readable label for an architect mode category tab.
let tabLabel = (cat: architectModeCategory): string =>
  switch cat {
  | Canvas => "Canvas"
  | Properties => "Properties"
  | AiSuggestions => "AI Suggestions"
  | Validation => "Validation"
  }

/// All category tabs in display order.
let allTabs: array<architectModeCategory> = [Canvas, Properties, AiSuggestions, Validation]

/// Count how many entities are currently selected.
let countSelectedEntities = (entities: array<placedEntity>): int =>
  entities->Array.filter(e => e.selected)->Array.length

/// Count entities matching a given kind string.
let countEntitiesByKind = (entities: array<placedEntity>, kind: string): int =>
  entities->Array.filter(e => e.kind === kind)->Array.length

/// Human-readable label for an editor tool.
let toolLabel = (tool: architectEditorTool): string =>
  switch tool {
  | SelectTool => "Select"
  | PlaceTool(kind) => `Place ${kind}`
  | EraseTool => "Erase"
  | WireTool => "Wire"
  | ZoneTool => "Zone"
  | PanTool => "Pan"
  }

/// Whether the undo stack has actions available.
let canUndo = (state: architectModeState): bool => state.undoStack->Array.length > 0

/// Whether the redo stack has actions available.
let canRedo = (state: architectModeState): bool => state.redoStack->Array.length > 0
