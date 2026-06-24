// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

/// Update handler for TangleViz topological programming visualizer.
let updateTangleViz = (model: model, msg: tangleVizMsg): (model, Tea_Cmd.t<msg>) => {
  let tv = model.tangleViz
  switch msg {
  | SetViewMode(mode) => ({...model, tangleViz: {...tv, viewMode: mode}}, Tea_Cmd.none)
  | SetInputText(text) => ({...model, tangleViz: {...tv, inputText: text}}, Tea_Cmd.none)
  | ParseInput => {
      // Parse braid word notation: space/comma-separated tokens like
      // "s1", "s2^-1", "s1 s2^-1 s1", "sigma1", "s3inv", etc.
      let input = String.trim(tv.inputText)
      if input === "" {
        (
          {
            ...model,
            tangleViz: {
              ...tv,
              braidWord: [],
              strandCount: 2,
              parsedProgram: Some(ParsedOk),
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      } else {
        let tokens =
          input
          ->String.replaceRegExp(/[,;\\s]+/g, " ")
          ->String.trim
          ->String.split(" ")
        let generators: array<braidGenerator> = []
        let parseError = ref(None)
        tokens->Array.forEach(token => {
          let t = String.trim(String.toLowerCase(token))
          if t !== "" && parseError.contents === None {
            let hasInverse =
              String.includes(t, "^-1") || String.includes(t, "inv") || String.includes(t, "-1")
            let numStr = String.replaceRegExp(t, /[^0-9]/g, "")
            switch Int.fromString(numStr) {
            | Some(idx) if idx >= 1 => {
                let _ = generators->Array.push({
                  index: idx,
                  exponent: hasInverse ? -1 : 1,
                })
              }
            | _ => parseError := Some(`Invalid generator: "${token}"`)
            }
          }
        })
        switch parseError.contents {
        | Some(err) => (
            {...model, tangleViz: {...tv, parsedProgram: Some(ParseFailed(err)), error: Some(err)}},
            Tea_Cmd.none,
          )
        | None => {
            let strandCount = TangleVizEngine.strandCountFromWord(generators)
            (
              {
                ...model,
                tangleViz: {
                  ...tv,
                  braidWord: generators,
                  strandCount,
                  parsedProgram: Some(ParsedOk),
                  error: None,
                  invariantResult: None,
                },
              },
              Tea_Cmd.none,
            )
          }
        }
      }
    }
  | ClearAll => ({...model, tangleViz: TangleVizEngine.defaultState}, Tea_Cmd.none)
  | LoadExample(generators) =>
    let strandCount = TangleVizEngine.strandCountFromWord(generators)
    (
      {
        ...model,
        tangleViz: {
          ...tv,
          braidWord: generators,
          strandCount,
          inputText: TangleVizEngine.braidWordToString(generators),
          parsedProgram: Some(ParsedOk),
          invariantResult: None,
          error: None,
        },
      },
      Tea_Cmd.none,
    )
  | SelectInvariant(inv) => (
      {...model, tangleViz: {...tv, selectedInvariant: Some(inv), invariantResult: None}},
      Tea_Cmd.none,
    )
  | ComputeInvariant =>
    switch tv.selectedInvariant {
    | None => (model, Tea_Cmd.none)
    | Some(inv) =>
      let result = TangleVizEngine.computeInvariant(inv, tv.braidWord)
      ({...model, tangleViz: {...tv, invariantResult: Some(result)}}, Tea_Cmd.none)
    }
  | DismissError => ({...model, tangleViz: {...tv, error: None}}, Tea_Cmd.none)
  }
}
