// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Reposystem Engine — pure computation for RSR compliance.
///
/// Computes compliance scores, aggregates statistics, filters repos,
/// and provides display helpers for the view layer.

open ReposystemModel

/// Human-readable label for an RSR requirement.
let requirementLabel = (req: rsrRequirement): string =>
  switch req {
  | EditorConfig => ".editorconfig"
  | AiManifest => "AI Manifest"
  | StateMachineReadable => "STATE.scm"
  | MetaMachineReadable => "META.scm"
  | EcosystemMachineReadable => "ECOSYSTEM.scm"
  | Justfile => "Justfile"
  | TopologyDiagram => "TOPOLOGY.md"
  | SecurityPolicy => "SECURITY.md"
  | LicenseFile => "LICENSE"
  | HypatiaScanWorkflow => "hypatia-scan.yml"
  }

/// Category tab label.
let categoryLabel = (cat: reposystemCategory): string =>
  switch cat {
  | RsrDashboard => "Dashboard"
  | RsrRepoList => "Repos"
  | RsrRequirements => "Requirements"
  | RsrLanguagePolicy => "Language Policy"
  }

/// Filter audits by repo name.
let filterAudits = (audits: array<repoCompliance>, query: string): array<repoCompliance> => {
  if query === "" {
    audits
  } else {
    let q = String.toLowerCase(query)
    audits->Array.filter(a => String.includes(String.toLowerCase(a.repoName), q))
  }
}

/// Compute aggregate statistics from per-repo audits.
let computeStats = (audits: array<repoCompliance>): complianceStats => {
  let totalRepos = Array.length(audits)
  let allRequirements: array<rsrRequirement> = [
    EditorConfig, AiManifest, StateMachineReadable, MetaMachineReadable,
    EcosystemMachineReadable, Justfile, TopologyDiagram, SecurityPolicy,
    LicenseFile, HypatiaScanWorkflow,
  ]

  let requirementRates = allRequirements->Array.map(req => {
    let metCount = audits->Array.filter(a =>
      a.results->Array.some(r => r.requirement === req && r.met)
    )->Array.length
    let rate = if totalRepos > 0 {
      Int.toFloat(metCount) /. Int.toFloat(totalRepos)
    } else {
      0.0
    }
    (req, rate, metCount)
  })

  let avgScore = if totalRepos > 0 {
    audits->Array.map(a => a.score)->Array.reduce(0.0, (acc, s) => acc +. s) /.
      Int.toFloat(totalRepos)
  } else {
    0.0
  }

  let fullyCompliant = audits->Array.filter(a => a.score >= 1.0)->Array.length

  {totalRepos, requirementRates, avgScore, fullyCompliant}
}

/// Parse compliance audits from JSON.
let parseAudits = (json: string): result<array<repoCompliance>, string> => {
  try {
    let parsed = JSON.parseExn(json)
    switch JSON.Classify.classify(parsed) {
    | Array(items) =>
      let audits = items->Array.filterMap(item => {
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
            let getFloat = (key: string): float =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => n
                | _ => 0.0
                }
              | None => 0.0
              }
            let getInt = (key: string): int =>
              switch Dict.get(obj, key) {
              | Some(v) =>
                switch JSON.Classify.classify(v) {
                | Number(n) => Float.toInt(n)
                | _ => 0
                }
              | None => 0
              }

            Some({
              repoName: getString("repo_name"),
              results: [], // Parsed separately if needed
              score: getFloat("score"),
              metCount: getInt("met_count"),
              totalCount: getInt("total_count"),
            })
          }
        | _ => None
        }
      })
      Ok(audits)
    | _ => Error("Expected array of compliance audits")
    }
  } catch {
  | _ => Error("Failed to parse compliance JSON")
  }
}

/// All RSR requirements.
let allRequirements: array<rsrRequirement> = [
  EditorConfig, AiManifest, StateMachineReadable, MetaMachineReadable,
  EcosystemMachineReadable, Justfile, TopologyDiagram, SecurityPolicy,
  LicenseFile, HypatiaScanWorkflow,
]

/// Find repos failing a specific requirement.
let reposFailingRequirement = (audits: array<repoCompliance>, req: rsrRequirement): array<repoCompliance> =>
  audits->Array.filter(a =>
    a.results->Array.some(r => r.requirement === req && !r.met)
  )

/// Find repos passing a specific requirement.
let reposPassingRequirement = (audits: array<repoCompliance>, req: rsrRequirement): array<repoCompliance> =>
  audits->Array.filter(a =>
    a.results->Array.some(r => r.requirement === req && r.met)
  )

/// Get compliance rate for a single requirement.
let requirementRate = (audits: array<repoCompliance>, req: rsrRequirement): float => {
  let total = Array.length(audits)
  if total === 0 {
    0.0
  } else {
    let passing = reposPassingRequirement(audits, req)->Array.length
    Int.toFloat(passing) /. Int.toFloat(total)
  }
}

/// Default initial state.
let defaultState: reposystemState = {
  loaded: false,
  loading: false,
  error: None,
  audits: [],
  stats: None,
  activeCategory: RsrDashboard,
  filterText: "",
  selectedRequirement: None,
}
