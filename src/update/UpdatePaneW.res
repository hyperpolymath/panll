// SPDX-License-Identifier: PMPL-1.0-or-later

/// Extracted sub-updater for Pane-W (World / Event Chains).
/// Orchestrates the visualization of complex temporal event chains,
/// security study reports, and panic-attacker integration.

open Model
open Msg

// ===========================================================================
// Pane-W Helpers
// ===========================================================================

/// Parse panic-attacker capability JSON response.
/// Extracts mode, binary path, and status detail from the backend probe result.
/// Expected JSON shape: { "mode": "full"|"fallback"|"unavailable",
///   "binary_path": "/path/to/binary", "status_detail": "..." }
/// Tea_Json decoder for panic-attacker capability response.
let panicAttackerCapabilityDecoder: Tea_Json.decoder<(
  string,
  option<string>,
  option<string>,
)> = Tea_Json.map3(
  (mode, binary, detail) => (mode, binary, detail),
  Decoders.fieldWithDefault("mode", Tea_Json.string, "unknown"),
  Decoders.optionalFieldDecoder("binary_path", Tea_Json.string),
  Decoders.optionalFieldDecoder("status_detail", Tea_Json.string),
)

let parsePanicAttackerCapability = (json: string): (string, option<string>, option<string>) =>
  Decoders.decodeWithDefault(panicAttackerCapabilityDecoder, ("unknown", None, None), json)

// ===========================================================================
// Pane-W Sub-Updater
// ===========================================================================

/// STATE TRANSITION: Pane-W (World / Event Chains)
/// Orchestrates the visualization of complex temporal event chains,
/// security study reports, and panic-attacker integration.
///
/// Returns `(model, Tea_Cmd.t<msg>)` because several handlers issue Tauri
/// commands (file dialogs, backend imports, security ambush runs).
let updatePaneW = (model: model, msg: paneWMsg): (model, Tea_Cmd.t<msg>) => {
  let paneW = model.paneW
  switch msg {
  // --- Content & view toggles (pure state) ---
  | UpdateContent(text) => ({...model, paneW: {...paneW, content: text}}, Tea_Cmd.none)
  | ToggleTopologyView => (
      {...model, paneW: {...paneW, topologyView: !paneW.topologyView}},
      Tea_Cmd.none,
    )
  | SetValidatedOutput(text) => (
      {...model, paneW: {...paneW, lastValidatedOutput: text}},
      Tea_Cmd.none,
    )
  | UpdateEventChainInput(text) => (
      {...model, paneW: {...paneW, eventChainInput: text}},
      Tea_Cmd.none,
    )
  | ClearEventChain => (
      {
        ...model,
        paneW: {
          ...paneW,
          eventChain: [],
          eventChainSummary: None,
          eventChainTimeline: None,
          eventChainInput: "",
          eventChainError: None,
        },
      },
      Tea_Cmd.none,
    )

  // --- Barycentre tour ---
  | StartTour => (
      {
        ...model,
        barycentreTour: {
          active: true,
          currentStep: TourIntro,
          completed: model.barycentreTour.completed,
        },
      },
      Tea_Cmd.none,
    )
  | NextTourStep => {
      let next = switch model.barycentreTour.currentStep {
      | TourIntro => TourBinaryStar
      | TourBinaryStar => TourBarycentrePosition
      | TourBarycentrePosition => TourOrbitalMetrics
      | TourOrbitalMetrics => TourContractiles
      | TourContractiles => TourSyncHealth
      | TourSyncHealth => TourComplete
      | TourComplete => TourComplete
      }
      let completed = next === TourComplete
      (
        {
          ...model,
          barycentreTour: {
            active: !completed,
            currentStep: next,
            completed: completed || model.barycentreTour.completed,
          },
        },
        Tea_Cmd.none,
      )
    }
  | PrevTourStep => {
      let prev = switch model.barycentreTour.currentStep {
      | TourIntro => TourIntro
      | TourBinaryStar => TourIntro
      | TourBarycentrePosition => TourBinaryStar
      | TourOrbitalMetrics => TourBarycentrePosition
      | TourContractiles => TourOrbitalMetrics
      | TourSyncHealth => TourContractiles
      | TourComplete => TourSyncHealth
      }
      ({...model, barycentreTour: {...model.barycentreTour, currentStep: prev}}, Tea_Cmd.none)
    }
  | CloseTour => (
      {...model, barycentreTour: {...model.barycentreTour, active: false}},
      Tea_Cmd.none,
    )

  // --- Inline event chain parsing from text input ---
  | ImportEventChain =>
    // PARSING: Transforms raw JSON input into a structured event chain.
    switch EventChain.parse(paneW.eventChainInput) {
    | Ok(payload) => (
        {
          ...model,
          paneW: {
            ...paneW,
            eventChain: payload.events,
            eventChainSummary: payload.summary,
            eventChainTimeline: payload.timeline,
            eventChainError: None,
          },
        },
        Tea_Cmd.none,
      )
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }

  // --- File import commands (issue Tauri commands, await result) ---
  | ImportEventChainFile => (
      model,
      GossamerCmd.openEventChainFile(result => PaneW(EventChainFileLoaded(result))),
    )
  | ImportPanicAttackerReportFile => (
      model,
      GossamerCmd.openPanicAttackerReportFile(result => PaneW(
        PanicAttackerReportPathLoaded(result),
      )),
    )
  | ImportLatestPanicAttacker => (
      model,
      GossamerCmd.importLatestPanicAttackerReport(result => PaneW(
        PanicAttackerImportLoaded(result),
      )),
    )
  | CheckPanicAttackerCapability => (
      model,
      GossamerCmd.getPanicAttackerCapability(result => PaneW(
        PanicAttackerCapabilityLoaded(result),
      )),
    )

  // --- File import results (parse response data) ---
  | EventChainFileLoaded(result) =>
    switch result {
    | Ok(contents) =>
      switch EventChain.parse(contents) {
      | Ok(payload) => (
          {
            ...model,
            paneW: {
              ...paneW,
              eventChain: payload.events,
              eventChainSummary: payload.summary,
              eventChainTimeline: payload.timeline,
              eventChainError: None,
            },
          },
          Tea_Cmd.none,
        )
      | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerReportPathLoaded(result) =>
    // Two-phase import: first get the file path, then ask backend to convert.
    switch result {
    | Ok(path) => (
        model,
        GossamerCmd.importPanicAttackerReport(path, result => PaneW(
          PanicAttackerImportLoaded(result),
        )),
      )
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerImportLoaded(result) =>
    switch result {
    | Ok(json) =>
      switch EventChain.parse(json) {
      | Ok(payload) => (
          {
            ...model,
            paneW: {
              ...paneW,
              eventChain: payload.events,
              eventChainSummary: payload.summary,
              eventChainTimeline: payload.timeline,
              eventChainError: None,
            },
          },
          Tea_Cmd.none,
        )
      | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
      }
    | Error(err) => ({...model, paneW: {...paneW, eventChainError: Some(err)}}, Tea_Cmd.none)
    }
  | PanicAttackerCapabilityLoaded(result) =>
    switch result {
    | Ok(json) => {
        let (mode, binary, detail) = parsePanicAttackerCapability(json)
        (
          {
            ...model,
            paneW: {
              ...paneW,
              panicAttackerMode: mode,
              panicAttackerBinary: binary,
              panicAttackerStatusDetail: detail,
            },
          },
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {
          ...model,
          paneW: {
            ...paneW,
            panicAttackerMode: "unavailable",
            panicAttackerStatusDetail: Some(err),
          },
        },
        Tea_Cmd.none,
      )
    }

  // --- Security menu interactions (pure state) ---
  | ToggleSecurityTools => (
      {...model, paneW: {...paneW, securityMenuExpanded: !paneW.securityMenuExpanded}},
      Tea_Cmd.none,
    )
  | OpenSecurityDialog(tool) => (
      {...model, paneW: {...paneW, securityDialogOpen: true, securityDialogTool: Some(tool)}},
      Tea_Cmd.none,
    )
  | CloseSecurityDialog => (
      {...model, paneW: {...paneW, securityDialogOpen: false, securityDialogTool: None}},
      Tea_Cmd.none,
    )
  | ToggleSecurityStudyView => (
      {...model, paneW: {...paneW, securityViewActive: !paneW.securityViewActive}},
      Tea_Cmd.none,
    )
  | SetSecurityTarget(t) => ({...model, paneW: {...paneW, securityTarget: t}}, Tea_Cmd.none)
  | SetSecurityTimeline(t) => ({...model, paneW: {...paneW, securityTimeline: t}}, Tea_Cmd.none)
  | SetSecurityAxes(a) => ({...model, paneW: {...paneW, securityAxes: a}}, Tea_Cmd.none)
  | SetSecurityIntensity(i) => ({...model, paneW: {...paneW, securityIntensity: i}}, Tea_Cmd.none)
  | SetSecurityDuration(d) => ({...model, paneW: {...paneW, securityDuration: d}}, Tea_Cmd.none)

  // --- Security command lifecycle ---
  | LoadSecurityTimelineFile => (
      model,
      GossamerCmd.openSecurityTimelineFile(result => PaneW(SecurityTimelineFileLoaded(result))),
    )
  | SecurityTimelineFileLoaded(result) =>
    switch result {
    | Ok(path) => ({...model, paneW: {...paneW, securityTimeline: path}}, Tea_Cmd.none)
    | Error(err) => ({...model, paneW: {...paneW, securityError: Some(err)}}, Tea_Cmd.none)
    }
  | LaunchSecurityAmbush => {
      // Gather options from current Pane-W state for the ambush command.
      let timeline = if paneW.securityTimeline !== "" {
        Some(paneW.securityTimeline)
      } else {
        None
      }
      let axes = if paneW.securityAxes !== "" {
        Some(paneW.securityAxes)
      } else {
        None
      }
      let durationSecs = switch Int.fromString(paneW.securityDuration) {
      | Some(d) => d
      | None => 30
      }
      (
        {...model, paneW: {...paneW, securityStatus: Some("Running..."), securityError: None}},
        GossamerCmd.runPanicAttackAmbush(
          paneW.securityTarget,
          timeline,
          axes,
          paneW.securityIntensity,
          durationSecs,
          result => PaneW(SecurityAmbushResult(result)),
        ),
      )
    }
  | SecurityAmbushResult(result) =>
    switch result {
    | Ok(json) =>
      switch EventChain.parse(json) {
      | Ok(payload) => (
          {
            ...model,
            paneW: {
              ...paneW,
              eventChain: payload.events,
              eventChainSummary: payload.summary,
              eventChainTimeline: payload.timeline,
              eventChainError: None,
              securityStatus: Some("Complete"),
              securityError: None,
            },
          },
          Tea_Cmd.none,
        )
      | Error(err) => (
          {...model, paneW: {...paneW, securityStatus: Some("Failed"), securityError: Some(err)}},
          Tea_Cmd.none,
        )
      }
    | Error(err) => (
        {...model, paneW: {...paneW, securityStatus: Some("Failed"), securityError: Some(err)}},
        Tea_Cmd.none,
      )
    }
  }
}
