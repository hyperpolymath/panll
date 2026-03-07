// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Farm Engine — pure computation for the Git-Private-Farm panel.
///
/// All functions are pure (no side effects, no API calls). Takes model data
/// and produces filtered/sorted/aggregated views. Parsing of JSON responses
/// from Tauri commands also lives here.

open FarmModel

/// Parse a priority string from the manifest into the typed enum.
let parsePriority = (s: string): farmPriority => {
  switch String.toLowerCase(s) {
  | "high" => High
  | "low" => Low
  | _ => Medium
  }
}

/// Human-readable label for a priority level.
let priorityLabel = (p: farmPriority): string => {
  switch p {
  | High => "High"
  | Medium => "Medium"
  | Low => "Low"
  }
}

/// CSS colour class for a priority level.
let priorityColour = (p: farmPriority): string => {
  switch p {
  | High => "text-red-400"
  | Medium => "text-amber-400"
  | Low => "text-gray-400"
  }
}

/// Human-readable label for a category tab.
let categoryLabel = (cat: farmCategory): string => {
  switch cat {
  | AllRepos => "All Repos"
  | ByGroup => "By Group"
  | ByLanguage => "By Language"
  | ByForge => "By Forge"
  | Enrollment => "Enrollment"
  | Health => "Health"
  }
}

/// All category tabs in display order.
let allCategories: array<farmCategory> = [
  AllRepos,
  ByGroup,
  ByLanguage,
  ByForge,
  Enrollment,
  Health,
]

/// Human-readable label for a sort order.
let sortLabel = (s: farmSortBy): string => {
  switch s {
  | SortByName => "Name"
  | SortByPriority => "Priority"
  | SortByLanguage => "Language"
  | SortByHealth => "Health"
  }
}

/// All sort options in display order.
let allSortOptions: array<farmSortBy> = [
  SortByName,
  SortByPriority,
  SortByLanguage,
  SortByHealth,
]

/// Filter repos by a text query (matches name or description, case-insensitive).
let filterRepos = (repos: array<farmRepo>, query: string): array<farmRepo> => {
  if query === "" {
    repos
  } else {
    let q = String.toLowerCase(query)
    repos->Array.filter(r =>
      String.includes(String.toLowerCase(r.name), q) ||
      String.includes(String.toLowerCase(r.description), q)
    )
  }
}

/// Sort repos by the given criterion.
let sortRepos = (repos: array<farmRepo>, sortBy: farmSortBy): array<farmRepo> => {
  let sorted = Array.copy(repos)
  sorted->Array.sort((a, b) => {
    switch sortBy {
    | SortByName => String.compare(a.name, b.name)
    | SortByLanguage => String.compare(a.language, b.language)
    | SortByPriority => {
        let rank = p =>
          switch p {
          | High => 0
          | Medium => 1
          | Low => 2
          }
        Int.compare(rank(a.priority), rank(b.priority))
      }
    | SortByHealth => {
        let score = r =>
          switch r.healthScore {
          | Some(s) => s
          | None => 999.0
          }
        Float.compare(score(a), score(b))
      }
    }
  })
  sorted
}

/// Group repos by their group field.
let groupByGroup = (repos: array<farmRepo>): array<(string, array<farmRepo>)> => {
  let groups: Dict.t<array<farmRepo>> = Dict.make()
  repos->Array.forEach(r => {
    let key = switch r.group {
    | Some(g) => g
    | None => "ungrouped"
    }
    let existing = switch Dict.get(groups, key) {
    | Some(arr) => arr
    | None => []
    }
    Dict.set(groups, key, Array.concat(existing, [r]))
  })
  let entries = Dict.toArray(groups)
  entries->Array.sort(((a, _), (b, _)) => String.compare(a, b))
  entries
}

/// Group repos by primary language.
let groupByLanguage = (repos: array<farmRepo>): array<(string, array<farmRepo>)> => {
  let groups: Dict.t<array<farmRepo>> = Dict.make()
  repos->Array.forEach(r => {
    let key = r.language === "" ? "unknown" : r.language
    let existing = switch Dict.get(groups, key) {
    | Some(arr) => arr
    | None => []
    }
    Dict.set(groups, key, Array.concat(existing, [r]))
  })
  let entries = Dict.toArray(groups)
  entries->Array.sort(((a, _), (b, _)) => String.compare(a, b))
  entries
}

/// Count repos per forge.
let countByForge = (repos: array<farmRepo>): array<(string, int)> => {
  let counts: Dict.t<int> = Dict.make()
  repos->Array.forEach(r => {
    r.forges->Array.forEach(f => {
      let n = switch Dict.get(counts, f.name) {
      | Some(c) => c
      | None => 0
      }
      Dict.set(counts, f.name, n + 1)
    })
  })
  let entries = Dict.toArray(counts)
  entries->Array.sort(((_, a), (_, b)) => Int.compare(b, a))
  entries
}

/// Parse a single repo from the JSON inventory response.
/// Expects fields: name, description, language, priority, forges (string array),
/// auto_propagate, group.
let parseRepoFromJson = (json: JSON.t): option<farmRepo> => {
  switch JSON.Classify.classify(json) {
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
      let getOptString = (key: string): option<string> =>
        switch Dict.get(obj, key) {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | String(s) => Some(s)
          | Null => None
          | _ => None
          }
        | None => None
        }
      let forgeNames: array<string> = switch Dict.get(obj, "forges") {
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
      let forges = forgeNames->Array.map(name => ({
        name,
        primary: name === "github",
      }: farmForge))

      let enrollment: enrollmentTier = switch Dict.get(obj, "enrollment") {
      | Some(v) =>
        switch JSON.Classify.classify(v) {
        | Object(enrollObj) => {
            let getEnrollBool = (key: string): bool =>
              switch Dict.get(enrollObj, key) {
              | Some(bv) =>
                switch JSON.Classify.classify(bv) {
                | Bool(b) => b
                | _ => false
                }
              | None => false
              }
            {
              farm: getEnrollBool("farm"),
              hypatia: getEnrollBool("hypatia"),
              fleet: getEnrollBool("fleet"),
            }
          }
        | _ => {farm: true, hypatia: false, fleet: false}
        }
      | None => {farm: true, hypatia: false, fleet: false}
      }

      Some({
        name: getString("name"),
        description: getString("description"),
        language: getString("language"),
        priority: parsePriority(getString("priority")),
        forges,
        autoPropagation: getBool("auto_propagate"),
        group: getOptString("group"),
        enrollment,
        healthScore: None,
        hasDependabotAlerts: false,
      })
    }
  | _ => None
  }
}

/// Parse the full inventory response from the farm_list_repos command.
/// Returns (repos, totalCount).
let parseInventory = (jsonStr: string): result<array<farmRepo>, string> => {
  try {
    let json = JSON.parseExn(jsonStr)
    switch JSON.Classify.classify(json) {
    | Object(obj) => {
        let repos = switch Dict.get(obj, "repos") {
        | Some(v) =>
          switch JSON.Classify.classify(v) {
          | Array(arr) => arr->Array.filterMap(parseRepoFromJson)
          | _ => []
          }
        | None => []
        }
        Ok(repos)
      }
    | _ => Error("Expected object in inventory response")
    }
  } catch {
  | _ => Error("Failed to parse inventory JSON")
  }
}
