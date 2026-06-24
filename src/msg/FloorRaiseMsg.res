// SPDX-License-Identifier: MPL-2.0

/// Messages for the Floor Raise campaign dashboard.

type floorRaiseMsg =
  | SetTab(FloorRaiseModel.floorRaiseTab)
  | ScanAdoption
  | AdoptionScanned(result<string, string>)
  | RunCampaign(string)
  | CampaignResult(result<string, string>)
  | ClearError
