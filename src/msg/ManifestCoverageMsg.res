// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Manifest Coverage scanner panel.

type manifestCoverageMsg =
  | SetTab(ManifestCoverageModel.manifestCoverageTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
