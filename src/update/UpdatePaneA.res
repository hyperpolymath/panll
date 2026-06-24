// SPDX-License-Identifier: MPL-2.0

/// PanLL Pane-A (Ambient) Update Logic.

open Model
open Msg

/// Update logic for the Ambient Substrate (Ergonomics).
let update = (model: model, msg: paneAMsg): (model, Tea_Cmd.t<msg>) => {
  switch msg {
  | ToggleExpansion => (
      {...model, paneA: {...model.paneA, expanded: !model.paneA.expanded}},
      Tea_Cmd.none,
    )
  | UpdateMetrics(index, antiInflammatory, humidity) => (
      {
        ...model,
        paneA: {
          ...model.paneA,
          vexationIndex: index,
          antiInflammatoryActive: antiInflammatory,
          humidity: humidity,
        },
      },
      Tea_Cmd.none,
    )
  }
}
