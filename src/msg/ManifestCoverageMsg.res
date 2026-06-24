// SPDX-License-Identifier: MPL-2.0

/// Messages for the Manifest Coverage scanner panel.

type manifestCoverageMsg =
  | SetTab(ManifestCoverageModel.manifestCoverageTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
