// SPDX-License-Identifier: MPL-2.0

/// Code MRI — Pattern Diagnostics sub-updater (Layer 3)

open Model
open Msg
open PatternDiagModel
open PatternDiagMsg

/// Handle pattern diagnostics messages.
let updatePatternDiag = (model: model, msg: patternDiagMsg): (model, Tea_Cmd.t<msg>) => {
  let pd = model.patternDiag
  switch msg {
  | AnalysePatterns => {
      // Run pattern analysis against the timeline snapshots.
      let patterns = PatternDiagEngine.analyseTimeline(model.codeMriTimeline.snapshots)
      // Award XP for any positive patterns detected.
      let profile = patterns->Array.reduce(pd.profile, (prof, p) =>
        PatternDiagEngine.awardXp(prof, p.kind)
      )
      let now = Date.toISOString(Date.make())
      (
        {
          ...model,
          patternDiag: {
            ...pd,
            patterns: Array.concat(patterns, pd.patterns),
            profile,
            lastAnalysis: Some(now),
          },
        },
        Tea_Cmd.none,
      )
    }
  | PatternsDetected(patterns) => (
      {
        ...model,
        patternDiag: {
          ...pd,
          patterns: Array.concat(patterns, pd.patterns),
          lastAnalysis: Some(Date.toISOString(Date.make())),
        },
      },
      Tea_Cmd.none,
    )
  | AcknowledgePattern(id) => {
      let patterns = pd.patterns->Array.map(p =>
        if p.id === id {
          {...p, acknowledged: true}
        } else {
          p
        }
      )
      ({...model, patternDiag: {...pd, patterns}}, Tea_Cmd.none)
    }
  | TogglePatternPanel => (
      {...model, patternDiag: {...pd, expanded: !pd.expanded}},
      Tea_Cmd.none,
    )
  | SetMinPatternSeverity(severity) => (
      {...model, patternDiag: {...pd, minSeverity: severity}},
      Tea_Cmd.none,
    )
  | ToggleGamification => (
      {...model, patternDiag: {...pd, gamificationEnabled: !pd.gamificationEnabled}},
      Tea_Cmd.none,
    )
  | ResetProfile => (
      {
        ...model,
        patternDiag: {
          ...pd,
          profile: {xp: [], totalXp: 0, badges: [], streaks: [], level: 1},
        },
      },
      Tea_Cmd.none,
    )
  }
}
