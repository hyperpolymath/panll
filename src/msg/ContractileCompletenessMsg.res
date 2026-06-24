// SPDX-License-Identifier: MPL-2.0

/// Messages for the Contractile Completeness scanner panel.

type contractileCompletenessMsg =
  | SetTab(ContractileCompletenessModel.contractileCompletenessTab)
  | ScanRepos
  | ReposScanned(result<string, string>)
  | SelectRepo(string)
  | ClearError
