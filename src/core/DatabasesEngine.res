// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Databases Engine — pure logic for the Databases panel.
///
/// Initialises per-module state from DatabaseRegistry, provides default state,
/// and contains utility functions for filtering, sorting, and aggregating
/// database module information.

open DatabaseModule
open DatabasesModel

/// Initialise the databases panel state with all registered modules.
let defaultState: databasesState = {
  modules: DatabaseRegistry.allModules()->Array.map(initModuleState),
  selectedModule: "verisimdb",
  activeCategory: DbDashboard,
  queryInput: "",
  queryLoading: false,
  queryHistory: [],
  schemaEntities: [
    { name: "octads", kind: "table", fields: ["id", "graph", "vector", "tensor", "semantic", "document", "temporal", "provenance", "spatial"], entryCount: 5 },
    { name: "entities", kind: "table", fields: ["id", "name", "modality", "created_at", "updated_at"], entryCount: 12 },
    { name: "drift_log", kind: "table", fields: ["id", "dimension", "score", "timestamp", "resolved"], entryCount: 24 },
    { name: "proof_certificates", kind: "table", fields: ["id", "type", "contract", "status", "hash"], entryCount: 8 },
    { name: "federation_peers", kind: "table", fields: ["node_id", "address", "state", "last_seen"], entryCount: 3 },
  ],
  selectedEntity: None,
  entityDetail: None,
  filterText: "",
  loading: false,
  error: None,
  lastTypeCheck: None,
  bojRouting: false,
}

/// Find a module state by ID.
let findModule = (state: databasesState, id: string): option<moduleState> => {
  state.modules->Array.find(m => m.config.id == id)
}

/// Get the currently selected module state.
let selectedModuleState = (state: databasesState): option<moduleState> => {
  findModule(state, state.selectedModule)
}

/// Update a specific module state by ID.
let updateModule = (state: databasesState, id: string, updater: moduleState => moduleState): databasesState => {
  {
    ...state,
    modules: state.modules->Array.map(m =>
      if m.config.id == id {
        updater(m)
      } else {
        m
      }
    ),
  }
}

/// Count connected modules.
let connectedCount = (state: databasesState): int => {
  state.modules->Array.filter(m =>
    switch m.connection {
    | Connected(_) => true
    | _ => false
    }
  )->Array.length
}

/// Count total capabilities across all modules.
let totalCapabilities = (state: databasesState): int => {
  state.modules->Array.reduce(0, (acc, m) => acc + Array.length(m.config.capabilities))
}

/// Filter schema entities by search text.
let filteredEntities = (state: databasesState): array<schemaEntity> => {
  if state.filterText == "" {
    state.schemaEntities
  } else {
    let needle = state.filterText->String.toLowerCase
    state.schemaEntities->Array.filter(e =>
      e.name->String.toLowerCase->String.includes(needle) ||
      e.kind->String.toLowerCase->String.includes(needle)
    )
  }
}

/// Add a query to the history (most recent first, capped at 100).
let addToHistory = (state: databasesState, entry: queryHistoryEntry): databasesState => {
  let history = [entry]->Array.concat(state.queryHistory)
  let capped = if Array.length(history) > 100 {
    history->Array.slice(~start=0, ~end=100)
  } else {
    history
  }
  { ...state, queryHistory: capped }
}

/// Connection status label for display.
let connectionLabel = (status: connectionStatus): string => {
  switch status {
  | Disconnected => "Disconnected"
  | Connecting => "Connecting..."
  | Connected(url) => "Connected (" ++ url ++ ")"
  | Error(msg) => "Error: " ++ msg
  }
}

/// Connection status CSS colour class.
let connectionColour = (status: connectionStatus): string => {
  switch status {
  | Disconnected => "bg-gray-600"
  | Connecting => "bg-amber-400 animate-pulse"
  | Connected(_) => "bg-emerald-400"
  | Error(_) => "bg-red-400"
  }
}

/// Module accent colour for UI differentiation.
let moduleAccent = (id: string): string => {
  switch id {
  | "verisimdb" => "#34d399"   // emerald
  | "quandledb" => "#818cf8"   // indigo
  | "lithoglyph" => "#fb923c"  // orange
  | _ => "#9ca3af"             // gray
  }
}

/// Module icon label.
let moduleIcon = (id: string): string => {
  switch id {
  | "verisimdb" => "VDB"
  | "quandledb" => "QDB"
  | "lithoglyph" => "LG"
  | _ => "DB"
  }
}
