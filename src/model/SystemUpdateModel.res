// SPDX-License-Identifier: PMPL-1.0-or-later

/// System Update model state — tracks component list, update summary,
/// loading state, and log visibility.

type systemUpdateState = {
  components: array<SystemUpdateModule.component>,
  summary: SystemUpdateModule.updateSummary,
  loading: bool,
  showLogs: bool,
  logs: array<{"timestamp": string, "summary": string}>,
  lastSummaryText: string,
  error: option<string>,
}

/// Initial state for the system update panel.
let init: systemUpdateState = {
  components: [],
  summary: {
    totalComponents: 0,
    upToDate: 0,
    updatesAvailable: 0,
    updating: 0,
    failed: 0,
    lastFullUpdate: None,
  },
  loading: false,
  showLogs: false,
  logs: [],
  lastSummaryText: "",
  error: None,
}
