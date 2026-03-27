// SPDX-License-Identifier: PMPL-1.0-or-later
// UpdateProtocolSquisher.res — Protocol Squisher sub-updater extracted from Update.res

open Model
open Msg

let updateProtocolSquisher = (model: model, msg: protocolSquisherMsg): (model, Tea_Cmd.t<msg>) => {
  let ps = model.protocolSquisher
  switch msg {
  | SetPsCategory(cat) => ({...model, protocolSquisher: {...ps, activeCategory: cat}}, Tea_Cmd.none)
  | CheckPsCli => (
      {...model, protocolSquisher: {...ps, loading: true}},
      ProtocolSquisherCmd.checkCli(result => ProtocolSquisher(PsCliResult(result))),
    )
  | PsCliResult(Ok(_)) => ({...model, protocolSquisher: {...ps, cliAvailable: true, loading: false, error: None}}, Tea_Cmd.none)
  | PsCliResult(Error(e)) => ({...model, protocolSquisher: {...ps, cliAvailable: false, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SetAnalyseInput(v) => ({...model, protocolSquisher: {...ps, analyseInput: v}}, Tea_Cmd.none)
  | RunAnalysis => (
      {...model, protocolSquisher: {...ps, loading: true, error: None, lastTypeCheck: None}},
      Tea_Cmd.batch(list{
        ProtocolSquisherCmd.analyse(ps.analyseInput, result => ProtocolSquisher(AnalysisResult(result))),
        TypeLLService.checkSchemaTypes(ps.analyseInput, "auto", result => ProtocolSquisher(SchemaTypeCheckResult(result))),
      }),
    )
  | AnalysisResult(Ok(json)) =>
    switch ProtocolSquisherEngine.parseAnalysis(json) {
    | Ok(result) => {
        // #6: Extract IR constraints from the analysis result automatically.
        let irConstraints = ProtocolSquisherEngine.extractIrConstraints(result)
        (
          {...model, protocolSquisher: {
            ...ps,
            loading: false,
            lastAnalysis: Some(result),
            analysisHistory: Array.concat([result], ps.analysisHistory),
            irConstraints,
            error: None,
          }},
          Tea_Cmd.none,
        )
      }
    | Error(e) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
    }
  | AnalysisResult(Error(e)) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SetCompareLeft(v) => ({...model, protocolSquisher: {...ps, compareLeftInput: v}}, Tea_Cmd.none)
  | SetCompareRight(v) => ({...model, protocolSquisher: {...ps, compareRightInput: v}}, Tea_Cmd.none)
  | RunComparison => (
      {...model, protocolSquisher: {...ps, loading: true, error: None}},
      ProtocolSquisherCmd.compare(
        ps.compareLeftInput,
        ps.compareRightInput,
        result => ProtocolSquisher(ComparisonResult(result)),
      ),
    )
  | ComparisonResult(Ok(json)) => {
      let parsed = ProtocolSquisherEngine.parseComparison(json)
      switch parsed {
      | Ok(comparison) => (
          {...model, protocolSquisher: {...ps, loading: false, error: None, lastComparison: Some(comparison)}},
          Tea_Cmd.none,
        )
      | Error(_) => (
          {...model, protocolSquisher: {...ps, loading: false, error: None}},
          Tea_Cmd.none,
        )
      }
    }
  | ComparisonResult(Error(e)) => ({...model, protocolSquisher: {...ps, loading: false, error: Some(e)}}, Tea_Cmd.none)
  | SchemaTypeCheckResult(Ok(json)) => {
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1}
      ({...model, protocolSquisher: {...ps, lastTypeCheck: Some(json)}, typell: newTypell}, Tea_Cmd.none)
    }
  | SchemaTypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  // #6: Import IR constraints as Panel-L symbolic constraints.
  | ImportIrConstraints => {
      let newConstraints = ps.irConstraints->Array.mapWithIndex((expr, idx) => {
        let c: symbolicConstraint = {
          id: `ps-ir-${Int.toString(idx)}`,
          expression: expr,
          active: true,
          pinned: false,
        }
        c
      })
      let existingConstraints = model.paneL.constraints
      let merged = Array.concat(existingConstraints, newConstraints)
      ({...model, paneL: {...model.paneL, constraints: merged}}, Tea_Cmd.none)
    }
  // #7: Toggle transport compatibility display in Panel-W.
  | ToggleTransportDisplay => (
      {...model, protocolSquisher: {...ps, transportDisplayActive: !ps.transportDisplayActive}},
      Tea_Cmd.none,
    )
  }
}
