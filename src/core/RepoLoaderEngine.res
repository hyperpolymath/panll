// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Repo Loader Engine — pure computation for the repository loading panel.
///
/// All functions are pure (no side effects, no API calls). Provides:
///   - Default state initialisation
///   - Category labels
///   - Suggestion filtering and sorting
///   - JSON parsing for Tauri command responses

open RepoLoaderModel

/// Human-readable label for a category tab.
let categoryLabel = (cat: repoLoaderCategory): string => {
  switch cat {
  | Browse => "Browse"
  | Configure => "Configure"
  | Recent => "Recent"
  | FarmSearch => "Farm Search"
  }
}

/// All category tabs in display order.
let allCategories: array<repoLoaderCategory> = [
  Browse,
  Configure,
  Recent,
  FarmSearch,
]

/// CSS class for suggestion priority badge.
let priorityColour = (priority: string): string => {
  switch priority {
  | "critical" => "bg-red-500/20 text-red-300"
  | "high" => "bg-orange-500/20 text-orange-300"
  | "medium" => "bg-amber-500/20 text-amber-300"
  | "low" => "bg-gray-500/20 text-gray-300"
  | _ => "bg-gray-500/20 text-gray-300"
  }
}

/// Filter suggestions to only enabled ones.
let enabledSuggestions = (suggestions: array<panelSuggestion>): array<panelSuggestion> => {
  suggestions->Array.filter(s => s.enabled)
}

/// Count enabled suggestions.
let enabledCount = (suggestions: array<panelSuggestion>): int => {
  Array.length(enabledSuggestions(suggestions))
}

/// Filter recent paths by a search query.
let filterRecent = (paths: array<string>, query: string): array<string> => {
  if query === "" {
    paths
  } else {
    let q = String.toLowerCase(query)
    paths->Array.filter(p => String.includes(String.toLowerCase(p), q))
  }
}

/// Default initial state for the Repo Loader panel.
let defaultState: repoLoaderState = {
  currentRepo: None,
  suggestions: [],
  recentPaths: [],
  activeCategory: Browse,
  scanning: false,
  searchText: "",
  error: None,
  saved: true,
}

/// Parse a RepoInfo from Tauri scan response JSON.
let parseRepoInfo = (obj: Dict.t<JSON.t>): option<repoInfo> => {
  let getString = (key: string): string =>
    switch Dict.get(obj, key) {
    | Some(v) =>
      switch JSON.Classify.classify(v) {
      | String(s) => s
      | _ => ""
      }
    | None => ""
    }
  let getBool = (key: string): bool =>
    switch Dict.get(obj, key) {
    | Some(v) =>
      switch JSON.Classify.classify(v) {
      | Bool(b) => b
      | _ => false
      }
    | None => false
    }
  let getStringArray = (key: string): array<string> =>
    switch Dict.get(obj, key) {
    | Some(v) =>
      switch JSON.Classify.classify(v) {
      | Array(arr) =>
        arr->Array.filterMap(item =>
          switch JSON.Classify.classify(item) {
          | String(s) => Some(s)
          | _ => None
          }
        )
      | _ => []
      }
    | None => []
    }

  Some({
    path: getString("path"),
    name: getString("name"),
    description: getString("description"),
    languages: getStringArray("languages"),
    hasMachineReadable: getBool("has_machine_readable"),
    hasPanelsManifest: getBool("has_panels_manifest"),
    hasAiManifest: getBool("has_ai_manifest"),
    hasState: getBool("has_state"),
  })
}

/// Parse panel suggestions from JSON array.
let parseSuggestions = (arr: array<JSON.t>): array<panelSuggestion> => {
  arr->Array.filterMap(item => {
    switch JSON.Classify.classify(item) {
    | Object(obj) => {
        let getString = (key: string): string =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | String(s) => s
            | _ => ""
            }
          | None => ""
          }
        let getBool = (key: string): bool =>
          switch Dict.get(obj, key) {
          | Some(v) =>
            switch JSON.Classify.classify(v) {
            | Bool(b) => b
            | _ => false
            }
          | None => false
          }
        Some({
          panelName: getString("panel_name"),
          reason: getString("reason"),
          priority: getString("priority"),
          enabled: getBool("enabled"),
        })
      }
    | _ => None
    }
  })
}

/// Parse the full scan result from the Tauri backend.
let parseScanResult = (jsonStr: string): result<(repoInfo, array<panelSuggestion>), string> => {
  try {
    let parsed = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) => {
        let repo = switch Dict.get(obj, "repo") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Object(repoObj) => parseRepoInfo(repoObj)
          | _ => None
          }
        | None => None
        }
        let suggestions = switch Dict.get(obj, "suggestions") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Array(arr) => parseSuggestions(arr)
          | _ => []
          }
        | None => []
        }
        switch repo {
        | Some(r) => Ok((r, suggestions))
        | None => Error("Failed to parse repo info")
        }
      }
    | _ => Error("Expected object in scan result")
    }
  } catch {
  | _ => Error("Failed to parse scan result JSON")
  }
}

/// Parse recent repos from JSON response.
let parseRecentPaths = (jsonStr: string): array<string> => {
  try {
    let parsed = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(parsed) {
    | Object(obj) =>
      switch Dict.get(obj, "repos") {
      | Some(v) =>
        switch JSON.Classify.classify(v) {
        | Array(arr) =>
          arr->Array.filterMap(item =>
            switch JSON.Classify.classify(item) {
            | Object(repoObj) =>
              switch Dict.get(repoObj, "path") {
              | Some(pathVal) =>
                switch JSON.Classify.classify(pathVal) {
                | String(s) => Some(s)
                | _ => None
                }
              | None => None
              }
            | _ => None
            }
          )
        | _ => []
        }
      | None => []
      }
    | _ => []
    }
  } catch {
  | _ => []
  }
}
