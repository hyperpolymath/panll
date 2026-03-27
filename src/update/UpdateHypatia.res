// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg

/// STATE TRANSITION: Hypatia (neurosymbolic scanner)
///
/// Handles loading network status, scan results, category navigation,
/// and text filtering. The backend is an Elixir Phoenix API.
let updateHypatia = (model: model, msg: hypatiaMsg): (model, Tea_Cmd.t<msg>) => {
  let hyp = model.hypatia
  switch msg {
  | LoadHypatia => (
      {...model, hypatia: {...hyp, loading: true, error: None}},
      Tea_Cmd.batch(list{
        HypatiaCmd.fetchNetworks(result => Hypatia(NetworksLoaded(result))),
        HypatiaCmd.fetchScans(result => Hypatia(ScansLoaded(result))),
        TypeLLService.checkConfigTypes("hypatia-scan-config", "hypatia", result => Hypatia(
          TypeCheckResult(result),
        )),
      }),
    )
  | NetworksLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch HypatiaEngine.parseNetworks(jsonStr) {
      | Ok(networks) => {
          // S5: Propagate Hypatia neural confidence to Panel-N autonomy.
          // Average confidence across active networks sets the autonomy ceiling.
          let activeNets = networks->Array.filter(n =>
            switch n.status {
            | NetActive => true
            | _ => false
            }
          )
          let avgConfidence = if Array.length(activeNets) > 0 {
            let total = activeNets->Array.reduce(0.0, (acc, n) => acc +. n.confidence)
            total /. Int.toFloat(Array.length(activeNets))
          } else {
            0.0
          }
          // Clamp autonomy to the confidence level — can't be more autonomous
          // than the neural networks are confident.
          let newAutonomy = Math.min(model.paneN.agency.autonomyLevel, avgConfidence)
          let newAgency = {...model.paneN.agency, autonomyLevel: newAutonomy}
          let newPaneN = {...model.paneN, agency: newAgency}
          (
            {
              ...model,
              paneN: newPaneN,
              hypatia: {
                ...hyp,
                loaded: true,
                loading: false,
                error: None,
                networks,
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => ({...model, hypatia: {...hyp, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, hypatia: {...hyp, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | ScansLoaded(result) =>
    switch result {
    | Ok(jsonStr) =>
      switch HypatiaEngine.parseScans(jsonStr) {
      | Ok(scans) => {
          let quarantined = scans->Array.reduce(0, (acc, s) => acc + s.quarantineCount)
          (
            {
              ...model,
              hypatia: {
                ...hyp,
                loaded: true,
                loading: false,
                scans,
                totalRepos: Array.length(scans),
                quarantinedCount: quarantined,
              },
            },
            Tea_Cmd.none,
          )
        }
      | Error(e) => ({...model, hypatia: {...hyp, loading: false, error: Some(e)}}, Tea_Cmd.none)
      }
    | Error(e) => ({...model, hypatia: {...hyp, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | SetHypatiaCategory(cat) => ({...model, hypatia: {...hyp, activeCategory: cat}}, Tea_Cmd.none)
  | SetHypatiaFilter(text) => ({...model, hypatia: {...hyp, filterText: text}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "hypatia", json)
      let newTypell = {
        ...model.typell,
        queriesServed: model.typell.queriesServed + 1,
        panelTypeChecks: checks,
      }
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) => // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  | SelectRecipe(id) => ({...model, hypatia: {...hyp, selectedRecipe: id}}, Tea_Cmd.none)
  | SetRecipeFilter(text) => ({...model, hypatia: {...hyp, recipeFilter: text}}, Tea_Cmd.none)
  }
}
