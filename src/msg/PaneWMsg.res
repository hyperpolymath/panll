// SPDX-License-Identifier: MPL-2.0

/// Messages for Pane-W (World/Barycentre) -- security and event chain pane that
/// aggregates panic-attacker data and renders the central canvas.

type paneWMsg =
  | UpdateContent(string)
  | ToggleTopologyView
  | SetValidatedOutput(string)
  | UpdateEventChainInput(string)
  | ImportEventChain
  | ImportEventChainFile
  | ImportPanicAttackerReportFile
  | ImportLatestPanicAttacker
  | CheckPanicAttackerCapability
  | EventChainFileLoaded(result<string, string>)
  | PanicAttackerReportPathLoaded(result<string, string>)
  | PanicAttackerImportLoaded(result<string, string>)
  | PanicAttackerCapabilityLoaded(result<string, string>)
  /// Security menu interactions and panic-attacker command lifecycle
  | ToggleSecurityTools
  | OpenSecurityDialog(string)
  | CloseSecurityDialog
  | ToggleSecurityStudyView
  | SetSecurityTarget(string)
  | SetSecurityTimeline(string)
  | SetSecurityAxes(string)
  | SetSecurityIntensity(string)
  | SetSecurityDuration(string)
  | LoadSecurityTimelineFile
  | SecurityTimelineFileLoaded(result<string, string>)
  | LaunchSecurityAmbush
  | SecurityAmbushResult(result<string, string>)
  | ClearEventChain
  /// Barycentre tour messages
  | StartTour
  | NextTourStep
  | PrevTourStep
  | CloseTour
