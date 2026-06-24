// SPDX-License-Identifier: MPL-2.0

/// Messages for the Vexometer Friction viewer panel.

type vexometerFrictionMsg =
  | SetTab(VexometerFrictionModel.vexometerFrictionTab)
  | MeasureAll
  | MeasureResult(result<string, string>)
  | SelectTool(string)
  | ClearError
