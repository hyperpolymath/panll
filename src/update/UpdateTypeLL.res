// SPDX-License-Identifier: MPL-2.0
open Model
open Msg

let updateTypeLL = (model: model, msg: typellMsg): (model, Tea_Cmd.t<msg>) => {
  let tl = model.typell
  switch msg {
  | SetTlCategory(cat) => ({...model, typell: {...tl, activeCategory: cat}}, Tea_Cmd.none)
  | SetViewLayer(vl) => ({...model, typell: {...tl, activeViewLayer: vl}}, Tea_Cmd.none)
  | CheckTlHealth => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.health(result => TypeLL(TlHealthResult(result))),
    )
  | TlHealthResult(Ok(_)) => (
      {...model, typell: {...tl, serverConnected: true, loading: false, error: None}},
      Tea_Cmd.none,
    )
  | TlHealthResult(Error(e)) => (
      {...model, typell: {...tl, serverConnected: false, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | UpdateCheckerInput(v) => ({...model, typell: {...tl, checkerInput: v}}, Tea_Cmd.none)
  | RunCheck => {
      let ctx = if tl.checkerContext !== "" {
        Some(tl.checkerContext)
      } else {
        None
      }
      let checkCmd = if tl.bojRouting {
        let ctxStr = switch ctx {
        | Some(c) => `, "context": "${c}"`
        | None => ""
        }
        BojCmd.invokeCartridgeWithLatency(
          "nesy-mcp",
          "check",
          `{"input": "${tl.checkerInput}"${ctxStr}}`,
          result => TypeLL(CheckResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        TypeLLCmd.check(tl.checkerInput, ctx, result => TypeLL(CheckResult(result)))
      }
      ({...model, typell: {...tl, loading: true, error: None}}, checkCmd)
    }
  | CheckResult(Ok(json)) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Ok(result) => {
        let narrative = TypeLLEngine.generateNarrative(result)
        (
          {
            ...model,
            typell: {
              ...tl,
              loading: false,
              lastCheckResult: Some(result),
              lastNarrative: Some(narrative),
              queriesServed: tl.queriesServed + 1,
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | CheckResult(Error(e)) => (
      {...model, typell: {...tl, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | RunInfer => {
      let inferCmd = if tl.bojRouting {
        BojCmd.invokeCartridgeWithLatency(
          "nesy-mcp",
          "infer",
          `{"input": "${tl.checkerInput}"}`,
          result => TypeLL(InferResult(result)),
          (cart, tool, elapsed) => RecordBojLatency(cart, tool, elapsed),
        )
      } else {
        TypeLLCmd.infer(tl.checkerInput, result => TypeLL(InferResult(result)))
      }
      ({...model, typell: {...tl, loading: true, error: None}}, inferCmd)
    }
  | InferResult(Ok(json)) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Ok(result) => {
        let narrative = TypeLLEngine.generateNarrative(result)
        (
          {
            ...model,
            typell: {
              ...tl,
              loading: false,
              lastCheckResult: Some(result),
              lastNarrative: Some(narrative),
              queriesServed: tl.queriesServed + 1,
              error: None,
            },
          },
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | InferResult(Error(e)) => (
      {...model, typell: {...tl, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | LoadSignatures => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.listSignatures(result => TypeLL(SignaturesLoaded(result))),
    )
  | SignaturesLoaded(Ok(jsonStr)) => {
      let sigs = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let name = gs(o, "name")
          if name !== "" {
            let tier = switch gs(o, "tier") {
            | "advanced" => TypeLLModel.TierAdvanced
            | "research" => TypeLLModel.TierResearch
            | _ => TypeLLModel.TierCore
            }
            Some({
              TypeLLModel.name,
              signature: gs(o, "signature"),
              module_: gs(o, "module"),
              tier,
            })
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, typell: {...tl, loading: false, signatures: sigs, error: None}}, Tea_Cmd.none)
    }
  | SignaturesLoaded(Error(e)) => (
      {...model, typell: {...tl, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | LoadUniverses => (
      {...model, typell: {...tl, loading: true}},
      TypeLLCmd.universes(result => TypeLL(UniversesLoaded(result))),
    )
  | UniversesLoaded(Ok(jsonStr)) => {
      let univs = switch Decoders.decodeOption(Tea_Json.value, jsonStr) {
      | Some(json) =>
        let arr = json->JSON.Decode.array->Option.getOr([])
        arr->Array.filterMap(item => {
          let o = item->JSON.Decode.object->Option.getOr(Dict.make())
          let gs = (d, k) => d->Dict.get(k)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          let gi = (d, k) =>
            d->Dict.get(k)->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0)->Float.toInt
          let name = gs(o, "name")
          if name !== "" {
            Some({
              TypeLLModel.level: gi(o, "level"),
              name,
              description: gs(o, "description"),
            })
          } else {
            None
          }
        })

      | None => []
      }
      ({...model, typell: {...tl, loading: false, universes: univs, error: None}}, Tea_Cmd.none)
    }
  | UniversesLoaded(Error(e)) => (
      {...model, typell: {...tl, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | SetSignatureFilter(v) => ({...model, typell: {...tl, signatureFilter: v}}, Tea_Cmd.none)
  | SetTierFilter(t) => ({...model, typell: {...tl, tierFilter: t}}, Tea_Cmd.none)
  | UpdateRefinementSpec(v) => ({...model, typell: {...tl, refinementSpec: v}}, Tea_Cmd.none)
  | UpdateRefinementConstraints(v) => (
      {...model, typell: {...tl, refinementConstraints: v}},
      Tea_Cmd.none,
    )
  | RunRefine => {
      let constraints = if tl.refinementConstraints !== "" {
        Some(tl.refinementConstraints)
      } else {
        None
      }
      (
        {...model, typell: {...tl, loading: true, error: None}},
        TypeLLCmd.refine(tl.refinementSpec, constraints, result => TypeLL(RefineResult(result))),
      )
    }
  | RefineResult(Ok(json)) =>
    switch TypeLLEngine.parseRefinementResult(json) {
    | Ok(result) => (
        {
          ...model,
          typell: {
            ...tl,
            loading: false,
            lastRefinement: Some(result),
            queriesServed: tl.queriesServed + 1,
            error: None,
          },
        },
        Tea_Cmd.none,
      )
    | Error(e) => ({...model, typell: {...tl, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | RefineResult(Error(e)) => (
      {...model, typell: {...tl, loading: false, error: Some(e)}},
      Tea_Cmd.none,
    )
  | ToggleTypellBojRouting => (
      {...model, typell: {...tl, bojRouting: !tl.bojRouting}},
      Tea_Cmd.none,
    )
  | SetDefaultDiscipline(d) => ({...model, typell: {...tl, defaultDiscipline: d}}, Tea_Cmd.none)
  | SetModuleDiscipline(scope, discipline) => {
      let existing = tl.disciplineDeclarations->Array.filter(d => d.scope !== scope)
      let decl: disciplineDeclaration = {
        scope,
        discipline,
        inferenceAllowed: true,
        enabledFeatures: TypeLLEngine.disciplineImpliedFeatures(discipline),
      }
      (
        {...model, typell: {...tl, disciplineDeclarations: Array.concat(existing, [decl])}},
        Tea_Cmd.none,
      )
    }
  | RemoveModuleDiscipline(scope) => {
      let filtered = tl.disciplineDeclarations->Array.filter(d => d.scope !== scope)
      ({...model, typell: {...tl, disciplineDeclarations: filtered}}, Tea_Cmd.none)
    }
  }
}
