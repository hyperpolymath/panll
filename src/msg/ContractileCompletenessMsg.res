// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Contractile Completeness scanner panel.

type contractileCompletenessMsg =
  | SetTab(ContractileCompletenessModel.contractileCompletenessTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
