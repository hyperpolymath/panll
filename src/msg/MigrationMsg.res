// SPDX-License-Identifier: PMPL-1.0-or-later

/// Migration Observatory messages -- migration health, sessions, submissions, merges.

open Model

type migrationMsg =
  /// Load migration data from panic-attack / feedback-o-tron.
  | LoadMigrationData
  /// Migration data loaded successfully.
  | MigrationDataLoaded(result<string, string>)
  /// Set migration category tab.
  | SetMigrationCategory(migrationCategory)
  /// Set report type selection.
  | SetMigrationReportType(migrationReportType)
  /// Filter repos by text.
  | SetMigrationFilter(string)
  /// Begin a new migration observation session.
  | BeginObservation(string, string)
  /// Observation session started.
  | ObservationStarted(result<string, string>)
  /// End current observation session.
  | EndObservation(string)
  /// Observation session ended.
  | ObservationEnded(result<string, string>)
  /// Approve a submission in the review queue.
  | ApproveSubmission(string)
  /// Reject a submission in the review queue.
  | RejectSubmission(string)
  /// Submit all approved submissions.
  | SubmitApproved
  /// Submissions sent.
  | SubmissionsResult(result<string, string>)
  /// Begin merge resolution.
  | BeginMergeResolution(string, string)
  /// Merge resolution started.
  | MergeResolutionStarted(result<string, string>)
  /// Rollback a merge session.
  | RollbackMerge(string)
  /// Accept a merge session.
  | AcceptMerge(string)
  /// Refresh migration health data.
  | RefreshMigrationHealth
  /// TypeLL cross-panel type check result for migration types.
  | TypeCheckResult(result<string, string>)
