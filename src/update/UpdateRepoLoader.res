// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Repo Loader — repository scanning, panel configuration.
///
/// Handles directory picking, repo scanning, panel suggestion management,
/// PANELS.a2ml saving, recent repo tracking, and farm search. When a repo
/// is loaded, dispatches Ai(BuildContext) to give the AI panel repo awareness.

open Model
open Msg

let updateRepoLoader = (model: model, msg: repoLoaderMsg): (model, Tea_Cmd.t<msg>) => {
  let rl = model.repoLoader
  switch msg {
  | PickRepoDirectory => (
      model,
      RepoLoaderCmd.pickDirectory(result => RepoLoader(DirectoryPicked(result))),
    )
  | DirectoryPicked(result) =>
    switch result {
    | Ok(path) => (
        {...model, repoLoader: {...rl, scanning: true, error: None}},
        RepoLoaderCmd.scan(path, result => RepoLoader(ScanResult(result))),
      )
    | Error(e) => ({...model, repoLoader: {...rl, error: Some(e)}}, Tea_Cmd.none)
    }
  | ScanRepo(path) => (
      {...model, repoLoader: {...rl, scanning: true, error: None}},
      Tea_Cmd.batch(list{
        RepoLoaderCmd.scan(path, result => RepoLoader(ScanResult(result))),
        TypeLLService.checkConfigTypes(path, "repoloader", result => RepoLoader(
          TypeCheckResult(result),
        )),
      }),
    )
  | ScanResult(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch RepoLoaderEngine.parseScanResult(jsonStr) {
      | Ok((repo, suggestions)) => (
          {
            ...model,
            repoLoader: {
              ...rl,
              currentRepo: Some(repo),
              suggestions,
              scanning: false,
              activeCategory: Configure,
              saved: false,
              error: None,
            },
          },
          // Push context to AI panel.
          Tea_Cmd.msg(Ai(BuildContext(repo.path))),
        )
      | Error(e) => ({...model, repoLoader: {...rl, scanning: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, repoLoader: {...rl, scanning: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | ToggleSuggestion(panelName) => {
      let newSuggestions = rl.suggestions->Array.map(s =>
        if s.panelName === panelName {
          {...s, enabled: !s.enabled}
        } else {
          s
        }
      )
      ({...model, repoLoader: {...rl, suggestions: newSuggestions, saved: false}}, Tea_Cmd.none)
    }
  | SavePanels =>
    switch rl.currentRepo {
    | Some(repo) => {
        // Serialise enabled suggestions as a JSON string for the backend.
        let enabledPanels = rl.suggestions->Array.filter(s => s.enabled)
        let jsonEntries = enabledPanels->Array.map(s => {
          `{"name":"${s.panelName}","enabled":true,"priority":"${s.priority}"}`
        })
        let jsonStr = "[" ++ Array.join(jsonEntries, ",") ++ "]"
        (
          model,
          RepoLoaderCmd.savePanels(repo.path, jsonStr, result => RepoLoader(PanelsSaved(result))),
        )
      }
    | None => ({...model, repoLoader: {...rl, error: Some("No repo loaded")}}, Tea_Cmd.none)
    }
  | PanelsSaved(result) =>
    switch result {
    | Ok(_) => ({...model, repoLoader: {...rl, saved: true, error: None}}, Tea_Cmd.none)
    | Error(e) => ({...model, repoLoader: {...rl, error: Some(e)}}, Tea_Cmd.none)
    }
  | LoadRecent => (model, RepoLoaderCmd.listRecent(result => RepoLoader(RecentLoaded(result))))
  | RecentLoaded(result) =>
    switch result {
    | Ok(jsonStr) => {
        let paths = RepoLoaderEngine.parseRecentPaths(jsonStr)
        ({...model, repoLoader: {...rl, recentPaths: paths}}, Tea_Cmd.none)
      }
    | Error(_) => (model, Tea_Cmd.none)
    }
  | SearchFarm(query) => (
      model,
      RepoLoaderCmd.searchFarm(query, result => RepoLoader(FarmSearchResult(result))),
    )
  | FarmSearchResult(_result) => // Farm search results are displayed directly — handled in UI.
    (model, Tea_Cmd.none)
  | SetRepoSearchText(text) => ({...model, repoLoader: {...rl, searchText: text}}, Tea_Cmd.none)
  | SetRepoCategory(cat) => ({...model, repoLoader: {...rl, activeCategory: cat}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "repoloader", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
