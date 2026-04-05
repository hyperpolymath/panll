// SPDX-License-Identifier: PMPL-1.0-or-later

/// Mass-panic panel messages -- assemblyline batch scanning, repo discovery,
/// incremental BLAKE3, verisim persistence, delta reporting, notifications.

type massPanicMsg =
  /// Set the repos directory path.
  | SetReposDirectory(string)
  /// Discover repos in the directory.
  | DiscoverRepos
  /// Repos discovered.
  | ReposDiscovered(result<string, string>)
  /// Run assemblyline on all repos.
  | RunAssemblyline
  /// Run assemblyline on selected repos only.
  | RunSelected
  /// Assemblyline scan result.
  | AssemblylineResult(result<string, string>)
  /// Poll scan progress.
  | PollProgress
  /// Progress update received.
  | ProgressUpdate(result<string, string>)
  /// Toggle incremental scanning (BLAKE3).
  | ToggleIncremental
  /// Toggle notification generation.
  | ToggleNotify
  /// Set filter mode.
  | SetFilterMode(MassPanicModel.repoFilterMode)
  /// Set sort mode.
  | SetSortMode(MassPanicModel.repoSortMode)
  /// Set search text.
  | SetSearchText(string)
  /// Toggle repo selection by index.
  | ToggleRepoSelection(int)
  /// Toggle select all.
  | ToggleSelectAll
  /// Toggle delta comparison view.
  | ToggleDelta
  /// Load delta comparison between latest two runs.
  | LoadDelta
  /// Delta loaded.
  | DeltaLoaded(result<string, string>)
  /// Generate notification summary.
  | GenerateNotification
  /// Notification generated.
  | NotificationGenerated(result<string, string>)
  /// Dismiss error.
  | DismissMassPanicError
  // -- Sub-view navigation --
  /// Switch active sub-view (scan / imaging / temporal).
  | SwitchView(MassPanicModel.massPanicView)
  // -- Imaging (fNIRS-style spatial health map) --
  /// Build system image from latest assemblyline results.
  | BuildImage
  /// System image built/loaded.
  | ImageLoaded(result<string, string>)
  /// Import a panll.system-image.v0 JSON file.
  | ImportImageFile
  /// Image file loaded.
  | ImageFileLoaded(result<string, string>)
  // -- Temporal navigation --
  /// List temporal snapshots.
  | ListSnapshots
  /// Snapshots listed.
  | SnapshotsLoaded(result<string, string>)
  /// Select a snapshot for comparison (slot 0 or 1).
  | SelectSnapshot(int, int)
  /// Diff selected snapshots.
  | DiffSnapshots
  /// Diff computed.
  | DiffLoaded(result<string, string>)
  /// Take a snapshot of the current image.
  | TakeSnapshot(string)
  /// Snapshot taken.
  | SnapshotTaken(result<string, string>)
  /// TypeLL cross-panel type check result for batch config types.
  | TypeCheckResult(result<string, string>)
