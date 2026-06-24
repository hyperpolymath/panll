// SPDX-License-Identifier: MPL-2.0

/// Messages for the Proven Adoption scanner panel.

type provenAdoptionMsg =
  | SetTab(ProvenAdoptionModel.provenAdoptionTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
