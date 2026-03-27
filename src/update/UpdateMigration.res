// SPDX-License-Identifier: PMPL-1.0-or-later

/// Sub-updater for Migration Observatory — health tracking, sessions,
/// submissions, merge resolver.

open Model
open Msg

let updateMigration = (model: model, msg: migrationMsg): (model, Tea_Cmd.t<msg>) => {
  let mig = model.migration
  switch msg {
  | LoadMigrationData => ({...model, migration: {...mig, loading: true, error: None}}, TypeLLService.checkMetadataTypes("migration-data", "migration", result => Migration(TypeCheckResult(result))))
  | MigrationDataLoaded(Ok(_data)) =>
    // Data parsing would happen here in a real implementation.
    // For now, mark as loaded.
    ({...model, migration: {
      ...mig,
      loaded: true,
      loading: false,
      error: None,
      avgHealth: MigrationEngine.computeAvgHealth(mig.repos),
      readyCount: MigrationEngine.countReady(mig.repos),
      blockedCount: MigrationEngine.countBlocked(mig.repos),
      totalRepos: Array.length(mig.repos),
    }}, Tea_Cmd.none)
  | MigrationDataLoaded(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | SetMigrationCategory(cat) =>
    ({...model, migration: {...mig, activeCategory: cat}}, Tea_Cmd.none)
  | SetMigrationReportType(rt) =>
    ({...model, migration: {...mig, activeReportType: rt}}, Tea_Cmd.none)
  | SetMigrationFilter(text) =>
    ({...model, migration: {...mig, filterText: text}}, Tea_Cmd.none)
  | BeginObservation(_repo, _label) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | ObservationStarted(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | ObservationStarted(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | EndObservation(_sessionId) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | ObservationEnded(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | ObservationEnded(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | ApproveSubmission(id) => {
      let updated = mig.submissions->Array.map(s =>
        if s.id === id {
          {...s, status: SubmissionApproved}
        } else {
          s
        }
      )
      ({...model, migration: {...mig, submissions: updated}}, Tea_Cmd.none)
    }
  | RejectSubmission(id) => {
      let updated = mig.submissions->Array.map(s =>
        if s.id === id {
          {...s, status: SubmissionRejected}
        } else {
          s
        }
      )
      ({...model, migration: {...mig, submissions: updated}}, Tea_Cmd.none)
    }
  | SubmitApproved =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | SubmissionsResult(Ok(_data)) =>
    // Mark approved submissions as submitted.
    let updated = mig.submissions->Array.map(s =>
      if s.status == SubmissionApproved {
        {...s, status: SubmissionSubmitted}
      } else {
        s
      }
    )
    ({...model, migration: {...mig, loading: false, submissions: updated}}, Tea_Cmd.none)
  | SubmissionsResult(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | BeginMergeResolution(_repo, _branch) =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | MergeResolutionStarted(Ok(_data)) =>
    ({...model, migration: {...mig, loading: false}}, Tea_Cmd.none)
  | MergeResolutionStarted(Error(err)) =>
    ({...model, migration: {...mig, loading: false, error: Some(err)}}, Tea_Cmd.none)
  | RollbackMerge(_sessionId) =>
    (model, Tea_Cmd.none)
  | AcceptMerge(_sessionId) =>
    (model, Tea_Cmd.none)
  | RefreshMigrationHealth =>
    ({...model, migration: {...mig, loading: true}}, Tea_Cmd.none)
  | TypeCheckResult(Ok(json)) => {
      let checks = model.typell.panelTypeChecks
      Dict.set(checks, "migration", json)
      let newTypell = {...model.typell, queriesServed: model.typell.queriesServed + 1, panelTypeChecks: checks}
      ({...model, typell: newTypell}, Tea_Cmd.none)
    }
  | TypeCheckResult(Error(_)) =>
    // TypeLL unavailable — degrade gracefully
    (model, Tea_Cmd.none)
  }
}
