// SPDX-License-Identifier: MPL-2.0

/// Code MRI — Attribution-to-Licensing sub-updater (Layer 4)

open Model
open Msg
open AttributionLicenseModel
open AttributionLicenseMsg

/// Handle attribution-to-licensing messages.
let updateAttributionLicense = (model: model, msg: attributionLicenseMsg): (model, Tea_Cmd.t<msg>) => {
  let al = model.attributionLicense
  switch msg {
  | StartLicenseScan => (
      {...model, attributionLicense: {...al, scanning: true}},
      Tea_Cmd.none, // Command layer dispatches the scan via Gossamer.
    )
  | ScanComplete(summaries) => {
      let allIssues = summaries->Array.flatMap(s => s.issues)
      let health = AttributionLicenseEngine.computeHealth(summaries)
      (
        {
          ...model,
          attributionLicense: {
            ...al,
            fileSummaries: summaries,
            issues: allIssues,
            health,
            scanning: false,
            lastScan: Some(Date.toISOString(Date.make())),
          },
        },
        Tea_Cmd.none,
      )
    }
  | ResolveIssue(id) => {
      let issues = al.issues->Array.map(i =>
        if i.id === id {
          {...i, resolved: true}
        } else {
          i
        }
      )
      let summaries = al.fileSummaries->Array.map(s => {
        let fileIssues = s.issues->Array.map(i =>
          if i.id === id {
            {...i, resolved: true}
          } else {
            i
          }
        )
        {...s, issues: fileIssues}
      })
      let health = AttributionLicenseEngine.computeHealth(summaries)
      (
        {
          ...model,
          attributionLicense: {...al, issues, fileSummaries: summaries, health},
        },
        Tea_Cmd.none,
      )
    }
  | ToggleLicensePanel => (
      {...model, attributionLicense: {...al, expanded: !al.expanded}},
      Tea_Cmd.none,
    )
  | SetMinLicenseSeverity(severity) => (
      {...model, attributionLicense: {...al, minSeverity: severity}},
      Tea_Cmd.none,
    )
  | ToggleShowResolved => (
      {...model, attributionLicense: {...al, showResolved: !al.showResolved}},
      Tea_Cmd.none,
    )
  | ScanFailed(_error) => (
      {...model, attributionLicense: {...al, scanning: false}},
      Tea_Cmd.none,
    )
  }
}
