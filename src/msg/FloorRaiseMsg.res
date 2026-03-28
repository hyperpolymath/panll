// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Floor Raise campaign dashboard.

type floorRaiseMsg =
  | SetTab(FloorRaiseModel.floorRaiseTab)
  | ScanAdoption
  | AdoptionScanned(result<string, string>)
  | RunCampaign(string)
  | CampaignResult(result<string, string>)
  | ClearError
