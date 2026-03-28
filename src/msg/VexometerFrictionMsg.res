// SPDX-License-Identifier: PMPL-1.0-or-later

/// Messages for the Vexometer Friction viewer panel.

type vexometerFrictionMsg =
  | SetTab(VexometerFrictionModel.vexometerFrictionTab)
  | MeasureAll
  | MeasureResult(result<string, string>)
  | SelectTool(string)
  | ClearError
