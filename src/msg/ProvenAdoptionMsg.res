// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Proven Adoption scanner panel.

type provenAdoptionMsg =
  | SetTab(ProvenAdoptionModel.provenAdoptionTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
