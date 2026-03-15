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

/// Tea_Json decoder for a repoInfo, bridging the existing parseRepoInfo parser.
let repoInfoDecoder: Tea_Json.decoder<repoInfo> = json => {
  switch json {
  | Object(dict) =>
    switch parseRepoInfo(dict) {
    | Some(v) => Ok(v)
    | None => Error(Tea_Json.Failure("Failed to decode repoInfo", json))
    }
  | _ => Error(Tea_Json.Failure("Expected an object for repoInfo", json))
  }
}

/// Tea_Json decoder for a panelSuggestion.
let suggestionDecoder: Tea_Json.decoder<panelSuggestion> = {
  open Decoders
  open Tea_Json
  map4(
    (panelName, reason, priority, enabled) => ({
      panelName,
      reason,
      priority,
      enabled,
    }: panelSuggestion),
    stringField("panel_name"),
    stringField("reason"),
    stringField("priority"),
    boolField("enabled"),
  )
}

/// Tea_Json decoder for the full scan result.
let scanResultDecoder: Tea_Json.decoder<(repoInfo, array<panelSuggestion>)> = {
  open Tea_Json
  map2(
    (repo, suggestions) => (repo, suggestions),
    field("repo", repoInfoDecoder),
    Decoders.fieldWithDefault("suggestions", Decoders.lenientArray(suggestionDecoder), []),
  )
}

/// Parse the full scan result from the Tauri backend.
let parseScanResult = (jsonStr: string): result<(repoInfo, array<panelSuggestion>), string> =>
  Decoders.decode(scanResultDecoder, jsonStr)

/// Tea_Json decoder for extracting a path string from a repo object.
let repoPathDecoder: Tea_Json.decoder<string> =
  Tea_Json.field("path", Tea_Json.string)

/// Tea_Json decoder for recent repo paths — extracts "repos" array, then "path" from each.
let recentPathsDecoder: Tea_Json.decoder<array<string>> =
  Decoders.fieldWithDefault(
    "repos",
    Decoders.lenientArray(repoPathDecoder),
    [],
  )

/// Parse recent repos from JSON response.
let parseRecentPaths = (jsonStr: string): array<string> =>
  Decoders.decodeWithDefault(recentPathsDecoder, [], jsonStr)
